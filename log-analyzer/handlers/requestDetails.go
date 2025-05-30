package handlers

import (
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// RequestQueryStats holds statistics for request queries
type RequestQueryStats struct {
	Query             string
	Count             int
	TotalTimeMillis   float64
	AverageTimeMillis float64 // Average duration per request
	MinTimeMillis     float64 // Minimum duration per request
	MaxTimeMillis     float64 // Maximum duration per request
}

// requestDetailsHandler serves the request details for the given path

func RequestDetailsHandler(w http.ResponseWriter, r *http.Request) {
	// Get the 'path' query parameter from the URL
	path := r.URL.Query().Get("path")
	if path == "" {
		http.Error(w, "Path query parameter is required", http.StatusBadRequest)
		return
	}

	// Get the relevant JSON file for this path
	tabUUID := r.URL.Query().Get("tabUUID")
	if tabUUID == "" {
		http.Error(w, "Tab UUID query parameter is required", http.StatusBadRequest)
		return
	}
	relevantFile, err := getRelevantJSONFile("uploads/", tabUUID)
	if err != nil {
		http.Error(w, "Failed to find the relevant data file", http.StatusInternalServerError)
		return
	}

	// Read request data from the relevant JSON file
	requestData, err := readRequestDataFromFile(relevantFile)
	if err != nil {
		http.Error(w, "Failed to load data from file", http.StatusInternalServerError)
		return
	}

	// Filter request details that match the given path
	var matchingDetails []FileDetail
	for _, details := range requestData {
		if details.RequestPath == path && details.CallType == "HTTP-In-Response" {
			matchingDetails = append(matchingDetails, details)
		}
	}

	// If no matching entries found, return an error
	if len(matchingDetails) == 0 {
		http.Error(w, "No matching data found for the given path", http.StatusNotFound)
		return
	}

	// Extract correlation IDs
	correlationIDs, err := extractCorrelationIDs(relevantFile, path)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	// Calculate request query statistics
	statsMap, err := calculateRequestQueryStatsExcludingCallTypes(requestData, correlationIDs)
	if err != nil {
		http.Error(w, "Failed to calculate query stats", http.StatusInternalServerError)
		return
	}

	// Convert map to slice for template rendering
	var stats []RequestQueryStats
	for _, stat := range statsMap {
		stats = append(stats, stat)
	}

	// Calculate total in-response time, query execution time, and their difference for the request path
	totalInResponseTime, totalQueryExecutionTime, timeDifference, err := calculateRequestTimes(requestData, path, statsMap)
	if err != nil {
		http.Error(w, "Failed to calculate request times", http.StatusInternalServerError)
		return
	}

	// Prepare data for rendering the template
	data := struct {
		RequestDetails          []FileDetail
		QueryStats              []RequestQueryStats
		TotalInResponseTime     float64
		TotalQueryExecutionTime float64
		TimeDifference          float64
		Path                    string
	}{
		RequestDetails:          matchingDetails,
		QueryStats:              stats,
		TotalInResponseTime:     totalInResponseTime,
		TotalQueryExecutionTime: totalQueryExecutionTime,
		TimeDifference:          timeDifference,
		Path:                    path,
	}

	// Load the HTML template
	templatePath := "template/requestDetails.html"
	tmpl, err := template.ParseFiles(templatePath)
	if err != nil {
		http.Error(w, "Error loading template", http.StatusInternalServerError)
		return
	}

	// Render the template with request details, query stats, and times
	w.Header().Set("Content-Type", "text/html")
	err = tmpl.Execute(w, data)
	if err != nil {
		http.Error(w, "Error rendering template", http.StatusInternalServerError)
		return
	}
}

// readRequestDataFromFile reads and parses JSON data from a file into a slice of FileDetail structs.
func readRequestDataFromFile(filename string) ([]FileDetail, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var requestData []FileDetail
	err = json.NewDecoder(file).Decode(&requestData)
	if err != nil {
		return nil, err
	}
	return requestData, nil
}

// getRelevantJSONFile searches for a JSON file in the specified directory that contains the given tabUUID in its name.
func getRelevantJSONFile(directory, tabUUID string) (string, error) {
	files, err := os.ReadDir(directory)
	if err != nil {
		return "", err
	}

	for _, file := range files {

		if file.IsDir() || !strings.HasSuffix(file.Name(), ".json") {
			continue
		}

		if strings.Contains(file.Name(), tabUUID) {

			return filepath.Join(directory, file.Name()), nil
		}
	}

	return "", fmt.Errorf("no JSON file found for tab UUID: %s", tabUUID)
}

// calculateRequestQueryStatsExcludingCallTypes calculates the count and total duration for each request query, excluding "HTTP-In-Response" and "HTTP-In-Request" call types
func calculateRequestQueryStatsExcludingCallTypes(requestData []FileDetail, correlationIDs []string) (map[string]RequestQueryStats, error) {
	// Create a map to store stats for each unique request query
	queryStats := make(map[string]RequestQueryStats)

	// Create a set for quick lookup of correlation IDs
	correlationIDSet := make(map[string]bool)
	for _, id := range correlationIDs {
		correlationIDSet[id] = true
	}

	// Iterate over request data to gather statistics
	for _, details := range requestData {
		// Exclude "HTTP-In-Response" and "HTTP-In-Request" call types
		if correlationIDSet[details.CorrelationId] && details.CallType != "HTTP-In-Response" && details.CallType != "HTTP-In-Request" {
			query := details.RequestQuery

			// Convert total duration from string to float
			duration, err := strconv.ParseFloat(details.TotalDurationForRequest, 64)
			if err != nil {
				return nil, fmt.Errorf("failed to parse duration: %w", err)
			}

			// Update the statistics
			stat, exists := queryStats[query]
			if exists {
				stat.Count++
				stat.TotalTimeMillis += duration

				// Update min and max time
				if duration < stat.MinTimeMillis {
					stat.MinTimeMillis = duration
				}
				if duration > stat.MaxTimeMillis {
					stat.MaxTimeMillis = duration
				}
			} else {
				// First occurrence, set min and max to the first value
				stat = RequestQueryStats{
					Query:           query,
					Count:           1,
					TotalTimeMillis: duration,
					MinTimeMillis:   duration,
					MaxTimeMillis:   duration,
				}
			}

			// Calculate average time
			stat.AverageTimeMillis = stat.TotalTimeMillis / float64(stat.Count)

			// Store updated stats
			queryStats[query] = stat
		}
	}

	return queryStats, nil
}

func extractCorrelationIDs(filename, requestPath string) ([]string, error) {
	// Read the request data from the JSON file
	requestData, err := readRequestDataFromFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read request data: %w", err)
	}

	// Use a map to store unique Correlation IDs
	correlationIDMap := make(map[string]struct{})
	for _, details := range requestData {
		if details.RequestPath == requestPath {
			correlationIDMap[details.CorrelationId] = struct{}{}
		}
	}

	// Convert map keys to a slice
	var correlationIDs []string
	for id := range correlationIDMap {
		correlationIDs = append(correlationIDs, id)
	}

	if len(correlationIDs) == 0 {
		return nil, fmt.Errorf("no correlation IDs found for request path: %s", requestPath)
	}

	return correlationIDs, nil
}

// calculateRequestTimes calculates the Total In Response Time, Total Query Execution Time, and their difference for a particular request path
func calculateRequestTimes(requestData []FileDetail, requestPath string, queryStats map[string]RequestQueryStats) (float64, float64, float64, error) {
	var totalInResponseTime, totalQueryExecutionTime float64

	// Iterate over the request data to accumulate the response time
	for _, details := range requestData {
		// Filter by the given request path and check for "HTTP-In-Response" call type
		if details.RequestPath == requestPath {
			// For "HTTP-In-Response", accumulate the response time
			if details.CallType == "HTTP-In-Response" {
				inResponseTime, err := strconv.ParseFloat(details.TotalDurationForRequest, 64)
				if err != nil {
					return 0, 0, 0, fmt.Errorf("failed to parse In-Response time: %w", err)
				}
				totalInResponseTime += inResponseTime
			}
		}
	}

	// Iterate over queryStats to sum TotalTimeMillis for the corresponding request path
	for _, stat := range queryStats {
		// Add the TotalTimeMillis for the query related to the request path
		totalQueryExecutionTime += stat.TotalTimeMillis
	}

	// Calculate the difference between Total Query Execution Time and Total In Response Time
	timeDifference := totalInResponseTime - totalQueryExecutionTime

	// Return the results
	return totalInResponseTime, totalQueryExecutionTime, timeDifference, nil
}
