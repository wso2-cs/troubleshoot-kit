package handlers

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

// Updated CorrelationQueryStats struct
type CorrelationQueryStats struct {
	Query             string
	Count             int
	TotalTimeMillis   float64
	AverageTimeMillis float64
	MinTimeMillis     float64
	MaxTimeMillis     float64
}

// Assuming you have a structure like this:
type LogData struct {
	Timestamp               time.Time
	TotalDurationForRequest float64
	CallType                string
	RequestQuery            string
}

type QueryTimeDifference struct {
	// TimeDifference float64   `json:"time_difference"`
	Query     string    `json:"query"`
	Duration  float64   `json:"duration"`
	Timestamp time.Time `json:"timestamp"`
	CallType  string    `json:"calltype"`
}

// correlationDetailsHandler serves all details for a given correlation ID
func CorrelationDetailsHandler(w http.ResponseWriter, r *http.Request) {
	// Get 'correlationID' and 'tabUUID' from query parameters
	correlationID := r.URL.Query().Get("correlationID")
	tabUUID := r.URL.Query().Get("tabUUID")

	if correlationID == "" || tabUUID == "" {
		http.Error(w, "Correlation ID and Tab UUID are required", http.StatusBadRequest)
		return
	}

	// Get the relevant JSON file
	relevantFile, err := getRelevantJSONFile1("uploads/", tabUUID)
	if err != nil {
		http.Error(w, "Failed to find the relevant data file", http.StatusInternalServerError)
		return
	}

	// Read request data from the JSON file
	requestData, err := readRequestDataFromFile1(relevantFile)
	if err != nil {
		http.Error(w, "Failed to load data from file", http.StatusInternalServerError)
		return
	}

	// Filter details excluding "HTTP-In-Request" and "HTTP-In-Response"
	var matchingCorrelationDetails []FileDetail
	for _, details := range requestData {
		if details.CorrelationId == correlationID {
			matchingCorrelationDetails = append(matchingCorrelationDetails, details)
		}
	}

	// If no matching details found, return an error
	if len(matchingCorrelationDetails) == 0 {
		http.Error(w, "No data found for the given Correlation ID", http.StatusNotFound)
		return
	}

	// Calculate query statistics for the correlation ID
	queryStats, err := CalculateQueryStatsForCorrelationID(matchingCorrelationDetails, correlationID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to calculate query stats: %v", err), http.StatusInternalServerError)
		return
	}

	// Calculate total duration
	totalDuration, totalExecutionTime, durationDifference, err := CalculateTotalDuration(correlationID, requestData, queryStats)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error calculating times: %v", err), http.StatusInternalServerError)
		return
	}

	// Create an array of LogData by parsing the Timestamp string into time.Time
	var logs []LogData
	for _, detail := range matchingCorrelationDetails {
		// Parse Timestamp string into time.Time
		timestamp, err := time.Parse("2006-01-02 15:04:05,000", detail.Timestamp)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to parse timestamp: %v", err), http.StatusInternalServerError)
			return
		}

		// Convert TotalDurationForRequest from string to float64
		duration, err := strconv.ParseFloat(detail.TotalDurationForRequest, 64)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to parse duration: %v", err), http.StatusInternalServerError)
			return
		}

		// Append parsed LogData
		logs = append(logs, LogData{
			Timestamp:               timestamp,
			TotalDurationForRequest: duration,
			CallType:                detail.CallType,
			RequestQuery:            detail.RequestQuery,
		})
	}

	// Perform the time difference calculations with query and duration details
	timeDifferences := calculateTimeDifferencesWithDetails(logs)

	// Log the time differences
	log.Println("Time Differences with Query Details:")
	for _, diff := range timeDifferences {
		log.Printf("Query: %s, Duration: %f ms, Timestamp: %v, CallType: %s",
			diff.Query, diff.Duration, diff.Timestamp, diff.CallType)
	}

	// Define template function map
	funcMap := template.FuncMap{
		"toJSON": toJSON,
	}

	// Load and parse template with function map
	templatePath := "template/correlationDetails.html"
	tmpl, err := template.New("correlationDetails.html").Funcs(funcMap).ParseFiles(templatePath)
	if err != nil {
		log.Printf("Error parsing template: %v", err)
		http.Error(w, "Error loading template", http.StatusInternalServerError)
		return
	}

	// Render the template with correlation details, query stats, total duration, and time differences
	w.Header().Set("Content-Type", "text/html")
	tmpl.Execute(w, struct {
		CorrelationDetails []FileDetail
		QueryStats         map[string]CorrelationQueryStats
		TotalDuration      float64
		TotalExecutionTime float64
		DurationDifference float64
		CorrelationID      string
		TimeDifferences    []QueryTimeDifference
	}{
		CorrelationDetails: matchingCorrelationDetails,
		QueryStats:         queryStats,
		TotalDuration:      totalDuration,
		TotalExecutionTime: totalExecutionTime,
		DurationDifference: durationDifference,
		CorrelationID:      correlationID,
		TimeDifferences:    timeDifferences, // Pass the updated struct
	})
}

// Convert data to JSON
func toJSON(data interface{}) (string, error) {
	bytes, err := json.Marshal(data)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func calculateTimeDifferencesWithDetails(logs []LogData) []QueryTimeDifference {
	var results []QueryTimeDifference

	// Iterate over all the logs to get query, duration, and timestamp for each log
	for i := 0; i < len(logs)-1; i++ {
		firstLog := logs[i]
		query := firstLog.RequestQuery               // Assuming RequestQuery is the query
		duration := firstLog.TotalDurationForRequest // Duration of the current log's query
		timestamp := firstLog.Timestamp              // Timestamp of the current log
		calltype := firstLog.CallType

		// Append the current log's details to the results
		results = append(results, QueryTimeDifference{
			Query:     query,
			Duration:  duration,
			Timestamp: timestamp,
			CallType:  calltype,
		})

		if i < len(logs)-1 {
			timeDiff := logs[i+1].Timestamp.Sub(logs[i].Timestamp).Milliseconds()

			var finalDiff float64
			var adjustedTimestamp time.Time

			if logs[i+1].CallType == "HTTP-In-Response" {
				finalDiff = float64(timeDiff)
				query = logs[i+1].RequestQuery // Use the actual query for "HTTP-In-Response"

				// The adjusted timestamp is the current timestamp minus the duration
				adjustedTimestamp = logs[i+1].Timestamp
				calltype = logs[i+1].CallType

			} else {
				// For other CallTypes, set query as "Empty" and use duration as time difference
				finalDiff = float64(timeDiff) - logs[i+1].TotalDurationForRequest // Subtract empty query duration
				query = "Idle"                                                    // Set the query as "Empty" for this condition
				// Adjust the timestamp for the "Empty" query
				adjustedTimestamp = logs[i+1].Timestamp.Add(-time.Duration(logs[i+1].TotalDurationForRequest) * time.Millisecond)
				calltype = logs[i+1].CallType
			}

			// Append structured data for each subsequent log entry
			results = append(results, QueryTimeDifference{
				Query:     query,
				Duration:  finalDiff, // Set the duration to the time difference in case of "Empty"
				Timestamp: adjustedTimestamp,
				CallType:  calltype,
			})
		}

	}

	return results
}

func getRelevantJSONFile1(directory, tabUUID string) (string, error) {
	files, err := os.ReadDir(directory)
	if err != nil {
		return "", err
	}

	for _, file := range files {
		if file.IsDir() {
			continue
		}
		if filepath.Ext(file.Name()) == ".json" && filepath.Base(file.Name()) == tabUUID+".json" {
			return filepath.Join(directory, file.Name()), nil
		}
	}

	return "", os.ErrNotExist
}

func readRequestDataFromFile1(filename string) ([]FileDetail, error) {
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

// CalculateQueryStatsForCorrelationID calculates request query statistics for a given correlation ID
func CalculateQueryStatsForCorrelationID(requestData []FileDetail, correlationID string) (map[string]CorrelationQueryStats, error) {
	// Create a map to store query statistics
	queryStats := make(map[string]CorrelationQueryStats)

	// Iterate through request data to find matching correlation ID
	for _, details := range requestData {
		// Skip entries with CallType "HTTP-In-Request" or "HTTP-In-Response"
		if details.CorrelationId == correlationID && details.CallType != "HTTP-In-Request" && details.CallType != "HTTP-In-Response" {
			query := details.RequestQuery

			// Convert total duration to float
			duration, err := strconv.ParseFloat(details.TotalDurationForRequest, 64)
			if err != nil {
				return nil, fmt.Errorf("failed to parse duration: %w", err)
			}

			// Update or initialize statistics
			stat, exists := queryStats[query]
			if exists {
				stat.Count++
				stat.TotalTimeMillis += duration

				// Update min and max times
				if duration < stat.MinTimeMillis {
					stat.MinTimeMillis = duration
				}
				if duration > stat.MaxTimeMillis {
					stat.MaxTimeMillis = duration
				}
			} else {
				// Initialize with the first duration value
				stat = CorrelationQueryStats{
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

	if len(queryStats) == 0 {
		return nil, fmt.Errorf("no queries found for correlation ID: %s", correlationID)
	}

	return queryStats, nil
}

// CalculateTotalDuration computes the total time based on the call type
func CalculateTotalDuration(correlationID string, requestData []FileDetail, queryStats map[string]CorrelationQueryStats) (float64, float64, float64, error) {
	var totalDuration float64
	var totalExecutionTime float64

	for _, details := range requestData {
		if details.CorrelationId == correlationID && details.CallType == "HTTP-In-Response" {
			duration, err := strconv.ParseFloat(details.TotalDurationForRequest, 64)
			if err != nil {
				return 0, 0, 0, fmt.Errorf("failed to parse duration for correlation ID %s: %w", details.CorrelationId, err)
			}
			totalDuration += duration
		}
	}

	// Sum up query execution times
	for _, stat := range queryStats {
		totalExecutionTime += stat.TotalTimeMillis
	}

	// Calculate the difference
	durationDifference := totalDuration - totalExecutionTime

	// Return both totalDuration and totalExecutionTime
	return totalDuration, totalExecutionTime, durationDifference, nil
}
