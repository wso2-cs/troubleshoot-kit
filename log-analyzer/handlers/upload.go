package handlers

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

// FileDetail holds the structured content extracted from an uploaded file
type FileDetail struct {
	Timestamp               string `json:"timestamp"`
	CorrelationId           string `json:"correlationId"`
	ThreadId                string `json:"threadId"`
	TotalDurationForRequest string `json:"totalDurationForRequest"`
	CallType                string `json:"callType"`
	StartTime               string `json:"startTime"`
	MethodName              string `json:"methodName"`
	RequestQuery            string `json:"requestQuery"`
	RequestPath             string `json:"requestPath"`
}

type TimeBucketStats struct {
	RequestCount  int
	ResponseCount int
	Durations     []float64
	AvgDuration   float64
	Percentile95  float64
}

var uploadedFiles []FileDetail                                   // uploadedFiles stores the content of all uploaded files
var requestPathStats = map[string]map[string]*RequestPathStats{} // The first key is tabUUID, and the second is RequestPath
// var httpResponses []FileDetail

// TemplateData holds data passed to the HTML template
type TemplateData struct {
	RequestPathStats    map[string]*RequestPathStats //A map (from a string key to a *RequestPathStats) containing statistics about request paths.
	QueryMetrics        map[string]*QueryMetrics     //A map (from a string key to a *QueryMetrics) that holds metrics related to request queries
	FileDetails         []FileDetail                 //A slice of FileDetail representing the processed file uploads.
	FileName            string
	FileNames           []string //A slice of strings that could list all file names available or processed.
	HttpResponses       []FileDetail
	OverallRequestStats OverallStats
	TimeBuckets         map[string]*TimeBucketStats
}

type OverallStats struct {
	Average            float64
	Percentile         float64
	TotalHTTPRequests  int // New field for tracking HTTP-IN-Requests
	TotalHTTPResponses int // New field for tracking HTTP-IN-Responses
	CompletionMessage  string
}

// Holds the following fields to track performance metrics:
type RequestPathStats struct {
	Count       int
	TotalTime   float64
	AverageTime float64
	MaxTime     float64
	MinTime     float64
	Durations   []float64
	Percentile  float64
}

// QueryMetrics holds statistics for request queries
type QueryMetrics struct {
	Count       int
	TotalTime   float64
	AverageTime float64
	MaxTime     float64
	MinTime     float64
	Durations   []float64
	Percentile  float64
}

// Stores statistics for request queries per tab
var queryMetricsMap = map[string]map[string]*QueryMetrics{}

// UploadHandler handles both the GET and POST requests
func UploadHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request:", r.Method)

	if r.Method == http.MethodPost {
		log.Println("Processing POST request")

		// Parse the multipart form with a 10MB memory limit
		err := r.ParseMultipartForm(10 << 20) // 10MB file size limit
		if err != nil {
			log.Printf("Error parsing multipart form: %v\n", err)
			http.Error(w, "Failed to parse multipart form", http.StatusBadRequest)
			return
		}

		// Retrieve the uploaded files using form key "uploadedFile"
		files := r.MultipartForm.File["uploadedFile"]
		if len(files) == 0 {
			log.Println("No files uploaded")
			http.Error(w, "No files uploaded", http.StatusBadRequest)
			return
		}

		var fileNames []string
		for _, fileHeader := range files {
			fileNames = append(fileNames, fileHeader.Filename)
		}

		// Loop through each uploaded file
		for _, fileHeader := range files {
			file, err := fileHeader.Open()
			if err != nil {
				log.Printf("Error opening file %s: %v\n", fileHeader.Filename, err)
				http.Error(w, "Error opening the file", http.StatusInternalServerError)
				return
			}

			//Process each file
			if err := processFile(file); err != nil {
				file.Close()
				log.Printf("Error processing file %s: %v\n", fileHeader.Filename, err)
				http.Error(w, "Error processing the file", http.StatusInternalServerError)
				return
			}
			file.Close()
		}

		//Get the unique tab identifier
		tabUUID := r.FormValue("uniqueID")

		//Initialize stats maps for this tab if not already present
		if _, exists := requestPathStats[tabUUID]; !exists {
			requestPathStats[tabUUID] = map[string]*RequestPathStats{}
		}
		if _, exists := queryMetricsMap[tabUUID]; !exists {
			queryMetricsMap[tabUUID] = map[string]*QueryMetrics{}
		}

		//Run computations
		calculateRequestPathStats(tabUUID, false)
		extractRequestQueries(tabUUID)
		calculateQueryMetrics(tabUUID)

		//Extract HTTPresponses from processed files
		httpResponses := extractHTTPResponses(uploadedFiles)

		//Variables for computing overall stats
		var (
			totalCount         int
			totalDuration      float64
			allDurations       []float64
			totalHTTPRequests  int
			totalHTTPResponses int
		)

		//Compute request/reponse statistics and durations
		for _, fileDetail := range uploadedFiles {
			switch strings.ToUpper(fileDetail.CallType) {
			case "HTTP-IN-REQUEST":
				totalHTTPRequests++
			case "HTTP-IN-RESPONSE":
				totalHTTPResponses++
				duration, err := strconv.ParseFloat(fileDetail.TotalDurationForRequest, 64)
				if err != nil {
					continue
				}
				totalCount++
				totalDuration += duration
				allDurations = append(allDurations, duration)
			}
		}

		//Calculate overall average and 95th percentile
		var overallAvg, overallPercentile float64
		if totalCount > 0 {
			overallAvg = totalDuration / float64(totalCount)
			sort.Float64s(allDurations)
			index := int(0.95 * float64(totalCount-1))
			overallPercentile = allDurations[index]
		}

		//Generate a completion message based on request-reponse count
		completionMessage := ""
		if totalHTTPRequests == totalHTTPResponses {
			completionMessage = "✅ All requests are completed in this file."
		} else {
			completionMessage = "⚠️ Not all requests are completed in this file. Some responses might be in another file."
		}

		//Prepare the overall stats
		overallStats := OverallStats{

			Average:            overallAvg,
			Percentile:         overallPercentile,
			TotalHTTPRequests:  totalHTTPRequests,
			TotalHTTPResponses: totalHTTPResponses,
			CompletionMessage:  completionMessage,
		}

		// Aggregate by time buckets (e.g., 1-minute buckets)
		timeBuckets := aggregateByTime(uploadedFiles, 1*time.Minute)

		//Log the bucket stats
		log.Println("---- Time Buckets ----")
		for bucketTime, stats := range timeBuckets {
			log.Printf("Time Bucket: %s | Request Count: %d | Average Duration: %.2f ms | 95th Percentile: %.2f ms\n | Response Count: %d |",
				bucketTime, stats.RequestCount, stats.AvgDuration, stats.Percentile95, stats.ResponseCount)
		}
		log.Println("---- End of Time Buckets ----")

		//Save uploaded file details to a JSON file
		saveFilesAsJSON(uploadedFiles, tabUUID)

		//Render the HTML template with the data
		tmpl := template.Must(template.New("index.html").Funcs(template.FuncMap{
			"marshal": marshal}).ParseFiles("template/index.html"))
		err = tmpl.Execute(w, TemplateData{
			RequestPathStats:    requestPathStats[tabUUID],
			QueryMetrics:        queryMetricsMap[tabUUID],
			FileDetails:         uploadedFiles,
			FileNames:           fileNames,
			HttpResponses:       httpResponses,
			OverallRequestStats: overallStats,
			TimeBuckets:         timeBuckets,
		})
		if err != nil {
			log.Printf("Error rendering template: %v\n", err)
			http.Error(w, "Error rendering template", http.StatusInternalServerError)
			return
		}

		//Clear the uploaded files after rendering
		uploadedFiles = nil
		log.Println("POST request completed successfully")

	} else if r.Method == http.MethodGet {
		log.Println("Processing GET request")

		tabUUID := r.URL.Query().Get("uniqueID")

		//Initialize maps if not present
		if _, exists := requestPathStats[tabUUID]; !exists {
			requestPathStats[tabUUID] = map[string]*RequestPathStats{}
		}
		if _, exists := queryMetricsMap[tabUUID]; !exists {
			queryMetricsMap[tabUUID] = map[string]*QueryMetrics{}
		}

		//Variables for overall stats
		var (
			totalCount         int
			totalDuration      float64
			allDurations       []float64
			totalHTTPRequests  int
			totalHTTPResponses int
		)

		//Calculate request/response counts and durations
		for _, fd := range uploadedFiles {
			switch strings.ToUpper(fd.CallType) {
			case "HTTP-IN-REQUEST":
				totalHTTPRequests++
			case "HTTP-IN-RESPONSE":
				totalHTTPResponses++
				duration, err := strconv.ParseFloat(fd.TotalDurationForRequest, 64)
				if err != nil {
					continue
				}
				totalCount++
				totalDuration += duration
				allDurations = append(allDurations, duration)
			}
		}

		var overallAvg, overallPercentile float64
		if totalCount > 0 {
			overallAvg = totalDuration / float64(totalCount)
			sort.Float64s(allDurations)
			index := int(0.95 * float64(totalCount-1))
			overallPercentile = allDurations[index]
		}

		overallStats := OverallStats{

			Average:            overallAvg,
			Percentile:         overallPercentile,
			TotalHTTPRequests:  totalHTTPRequests,
			TotalHTTPResponses: totalHTTPResponses,
		}

		// Render the results using the HTML template
		tmpl := template.Must(template.New("index.html").Funcs(template.FuncMap{
			"marshal": marshal}).ParseFiles("template/index.html"))
		err := tmpl.Execute(w, TemplateData{
			RequestPathStats:    requestPathStats[tabUUID],
			QueryMetrics:        queryMetricsMap[tabUUID],
			HttpResponses:       extractHTTPResponses(uploadedFiles),
			OverallRequestStats: overallStats,
		})
		if err != nil {
			log.Printf("Error rendering template: %v\n", err)
			http.Error(w, "Error rendering template", http.StatusInternalServerError)
			return
		}

		log.Println("GET request completed successfully")

	} else {
		log.Println("Invalid request method:", r.Method)
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
	}
}

// marshal is a helper function used to convert Go data structures to JSON  so that they can be safely embedded into HTML templates
func marshal(v interface{}) template.JS {
	a, err := json.Marshal(v)
	if err != nil {
		return template.JS("null")
	}
	// Return the JSON result as a template.JS type
	return template.JS(a)
}

// aggregateByTime groups the uploaded log file entries into time buckets and calculates average duration and 95th percentile of HTTP response durations within each bucket
func aggregateByTime(uploadedFiles []FileDetail, bucketDuration time.Duration) map[string]*TimeBucketStats {
	// Define the layout of the timestamp in the logs
	const customLayout = "2006-01-02 15:04:05,000"

	// Create a map to hold time buckets
	buckets := make(map[string]*TimeBucketStats)

	for _, f := range uploadedFiles {

		// Parse the timestamp string to Go's time.Time format
		t, err := time.Parse(customLayout, f.Timestamp)
		if err != nil {
			log.Printf("Invalid timestamp: %s\n", f.Timestamp)
			continue
		}

		bucketTime := t.Truncate(bucketDuration).Format("15:04:05")

		// Initialize a new bucket if one doesn't already exist for this time
		if _, exists := buckets[bucketTime]; !exists {
			buckets[bucketTime] = &TimeBucketStats{Durations: []float64{}}
		}
		bucket := buckets[bucketTime]

		switch f.CallType {
		case "HTTP-In-Request":
			bucket.RequestCount++

		case "HTTP-In-Response":
			bucket.ResponseCount++

			duration, err := strconv.ParseFloat(f.TotalDurationForRequest, 64)
			if err != nil {
				log.Printf("Invalid duration: %s\n", f.TotalDurationForRequest)
				continue
			}

			// Add duration to the bucket's list for stats calculation
			bucket.Durations = append(bucket.Durations, duration)
		}
	}

	// Compute stats for responses
	for _, bucket := range buckets {
		if len(bucket.Durations) == 0 {
			continue
		}
		total := 0.0
		sort.Float64s(bucket.Durations)
		for _, d := range bucket.Durations {
			total += d
		}
		bucket.AvgDuration = total / float64(len(bucket.Durations))
		idx := int(0.95 * float64(len(bucket.Durations)-1))
		bucket.Percentile95 = bucket.Durations[idx]
	}

	return buckets
}

func extractHTTPResponses(uploadedFiles []FileDetail) []FileDetail {
	var httpResponses []FileDetail

	for _, fileDetail := range uploadedFiles {
		if strings.EqualFold(fileDetail.CallType, "HTTP-IN-Response") {
			httpResponses = append(httpResponses, fileDetail)
		}
	}

	return httpResponses
}

// processFile processes the uploaded file and extracts the details
func processFile(file io.Reader) error {
	content, err := io.ReadAll(file)
	if err != nil {
		return err
	}

	extractFileDetails(string(content))
	return nil
}

// extractFileDetails parses the content and extracts structured fields for each line
func extractFileDetails(content string) {
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		fields := strings.Split(line, "|")
		if len(fields) >= 9 {
			requestPath := strings.TrimSpace(fields[8])

			// Check if RequestPath ends with any excluded extensions
			excludedExtensions := []string{".js", ".js(1)", ".ttf", ".css", ".gif", ".ico", ".png", ".jsf", ".woff", ".woff2", ".jpg", ".map"}
			exclude := false
			for _, ext := range excludedExtensions {
				if strings.HasSuffix(requestPath, ext) {
					exclude = true
					break
				}
			}

			// Only append if the RequestPath does not match excluded extensions
			if !exclude {
				fileDetail := FileDetail{
					Timestamp:               strings.TrimSpace(fields[0]),
					CorrelationId:           strings.TrimSpace(fields[1]),
					ThreadId:                strings.TrimSpace(fields[2]),
					TotalDurationForRequest: strings.TrimSpace(fields[3]),
					CallType:                strings.TrimSpace(fields[4]),
					StartTime:               strings.TrimSpace(fields[5]),
					MethodName:              strings.TrimSpace(fields[6]),
					RequestQuery:            strings.TrimSpace(fields[7]),
					RequestPath:             requestPath,
				}
				uploadedFiles = append(uploadedFiles, fileDetail)
			}
		}
	}
}

// calculateRequestPathStats computes detailed statistics for each request path
// from the uploaded files, including count, min/max/avg duration, and 95th percentile.
// It also provides global stats and checks if all requests have matching responses.
func calculateRequestPathStats(tabUUID string, resetStats bool) {

	// If reset is requested, clear the existing stats for this tab
	if resetStats {
		requestPathStats[tabUUID] = map[string]*RequestPathStats{}
	}

	// Global counters and duration collectors
	var totalHTTPRequests int
	var totalHTTPResponses int
	var totalHTTPDuration float64
	var allDurations []float64

	// Maps to track unique correlation IDs of requests and responses
	requestCorrelationIDs := make(map[string]struct{})
	responseCorrelationIDs := make(map[string]struct{})

	// Loop over each uploaded file log entry
	for _, fileDetail := range uploadedFiles {
		// If this is an HTTP-IN-Request, track it
		if strings.EqualFold(fileDetail.CallType, "HTTP-IN-Request") {
			totalHTTPRequests++
			requestCorrelationIDs[fileDetail.CorrelationId] = struct{}{}
		}

		// If this is an HTTP-IN-Response, process its duration
		if strings.EqualFold(fileDetail.CallType, "HTTP-IN-Response") {
			duration, err := strconv.ParseFloat(fileDetail.TotalDurationForRequest, 64)
			if err != nil {
				continue // Skip invalid durations
			}

			// Update global counters
			totalHTTPResponses++
			totalHTTPDuration += duration
			allDurations = append(allDurations, duration)
			responseCorrelationIDs[fileDetail.CorrelationId] = struct{}{}

			// Initialize stats for this request path if not already
			if _, exists := requestPathStats[tabUUID][fileDetail.RequestPath]; !exists {
				requestPathStats[tabUUID][fileDetail.RequestPath] = &RequestPathStats{
					MaxTime:   duration,
					MinTime:   duration,
					Durations: []float64{},
				}
			}

			// Update request path-specific statistics
			stats := requestPathStats[tabUUID][fileDetail.RequestPath]
			stats.Count++
			stats.TotalTime += duration
			stats.Durations = append(stats.Durations, duration)
			stats.AverageTime = stats.TotalTime / float64(stats.Count)

			if duration > stats.MaxTime {
				stats.MaxTime = duration
			}
			if stats.Count > 1 && duration < stats.MinTime {
				stats.MinTime = duration
			}
		}
	}

	// Calculate 95th percentile for each request path
	for _, stats := range requestPathStats[tabUUID] {
		if len(stats.Durations) > 0 {
			sort.Float64s(stats.Durations)
			index := int(0.95 * float64(len(stats.Durations)-1))
			stats.Percentile = stats.Durations[index]
		}
	}

	// Print global stats
	if totalHTTPResponses > 0 {
		sort.Float64s(allDurations)
		globalAverage := totalHTTPDuration / float64(totalHTTPResponses)
		globalPercentile := allDurations[int(0.95*float64(len(allDurations)-1))]

		fmt.Printf("Total HTTP-IN-Requests: %d\n", totalHTTPRequests)
		fmt.Printf("Total HTTP-IN-Responses: %d\n", totalHTTPResponses)
		fmt.Printf("Overall Average Duration: %.2f ms\n", globalAverage)
		fmt.Printf("Overall 95th Percentile Duration: %.2f ms\n", globalPercentile)
	}

	// Check if all request correlation IDs have matching response correlation IDs
	allMatched := true
	for id := range requestCorrelationIDs {
		if _, found := responseCorrelationIDs[id]; !found {
			allMatched = false
			break
		}
	}

	if allMatched {
		fmt.Println("✅ All requests have matching responses in this file.")
	} else {
		fmt.Println("⚠️  Not all requests have matching responses. Some responses might be in another file.")
	}
}

func saveFilesAsJSON(uploadedFiles []FileDetail, tabUUID string) {
	// Use the tabUUID to generate a unique file name
	fileName := fmt.Sprintf("uploads/%s.json", tabUUID)

	// Check if the file exists
	var existingFiles []FileDetail // Replace 'YourFileType' with the actual struct type of uploadedFiles

	if _, err := os.Stat(fileName); err == nil {
		// File exists, read existing content
		existingFile, err := os.Open(fileName)
		if err != nil {
			fmt.Println("Error opening existing JSON file:", err)
			return
		}
		defer existingFile.Close()

		// Decode existing JSON data
		decoder := json.NewDecoder(existingFile)
		err = decoder.Decode(&existingFiles)
		if err != nil {
			fmt.Println("Error decoding existing JSON data:", err)
			return
		}
	} else if !os.IsNotExist(err) {
		fmt.Println("Error checking if file exists:", err)
		return
	}

	// Append new uploadedFiles to existing data
	combinedFiles := append(existingFiles, uploadedFiles...)

	// Create or overwrite the file with updated data
	file, err := os.Create(fileName)
	if err != nil {
		fmt.Println("Error creating JSON file:", err)
		return
	}
	defer file.Close()

	// Write the combined data to the file
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	err = encoder.Encode(combinedFiles)
	if err != nil {
		fmt.Println("Error encoding JSON data:", err)
		return
	}

	fmt.Printf("File successfully saved to: %s\n", fileName)
}

func extractRequestQueries(tabUUID string) {
	// Ensure the tabUUID exists in queryMetricsMap, if not, initialize it
	if _, exists := queryMetricsMap[tabUUID]; !exists {
		queryMetricsMap[tabUUID] = map[string]*QueryMetrics{}
	}

	for _, fileDetail := range uploadedFiles {
		// Skip if CallType is "HTTP-IN-Request" or "HTTP-IN-Response"
		if strings.EqualFold(fileDetail.CallType, "HTTP-IN-Request") || strings.EqualFold(fileDetail.CallType, "HTTP-IN-Response") {
			continue
		}

		query := strings.TrimSpace(fileDetail.RequestQuery)
		if query == "" {
			continue // Skip empty queries
		}

		// Initialize metrics for a new request query if it doesn't exist
		if _, exists := queryMetricsMap[tabUUID][query]; !exists {
			queryMetricsMap[tabUUID][query] = &QueryMetrics{
				MaxTime: 0,   // Initialize MaxTime to 0
				MinTime: 1e9, // Start MinTime with a very large number (1 billion)
			}
		}
	}
}

func calculateQueryMetrics(tabUUID string) {
	for _, fileDetail := range uploadedFiles {
		// Skip if CallType is "HTTP-IN-Request" or "HTTP-IN-Response"
		if strings.EqualFold(fileDetail.CallType, "HTTP-IN-Request") || strings.EqualFold(fileDetail.CallType, "HTTP-IN-Response") {
			continue
		}

		query := strings.TrimSpace(fileDetail.RequestQuery)
		if query == "" {
			continue // Skip empty queries
		}

		duration, err := strconv.ParseFloat(fileDetail.TotalDurationForRequest, 64)
		if err != nil {
			continue // Skip invalid durations
		}

		// Ensure the query exists in the map
		if _, exists := queryMetricsMap[tabUUID][query]; !exists {
			if queryMetricsMap[tabUUID] == nil {
				queryMetricsMap[tabUUID] = make(map[string]*QueryMetrics)
			}
			queryMetricsMap[tabUUID][query] = &QueryMetrics{
				MaxTime:   0,
				MinTime:   1e9, // Set a high initial MinTime
				Durations: []float64{},
			}
		}

		metrics := queryMetricsMap[tabUUID][query]
		metrics.Count++
		metrics.TotalTime += duration
		metrics.AverageTime = metrics.TotalTime / float64(metrics.Count)
		metrics.Durations = append(metrics.Durations, duration)

		// Update MaxTime if the current duration is greater
		if duration > metrics.MaxTime {
			metrics.MaxTime = duration
		}

		// Update MinTime
		if duration < metrics.MinTime {
			metrics.MinTime = duration
		}
	}

	//Calculate the 95th percentile for each query
	for _, queryMetrics := range queryMetricsMap[tabUUID] {
		sort.Float64s(queryMetrics.Durations)
		n := len(queryMetrics.Durations)
		if n > 0 {
			index := int(float64(n)*0.95+0.5) - 1
			if index >= n {
				index = n - 1
			}
			queryMetrics.Percentile = queryMetrics.Durations[index]
		}
	}
}
