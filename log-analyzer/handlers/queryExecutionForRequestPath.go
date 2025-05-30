package handlers

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// QueryExecutionsForRequestHandler processes the query executions for a given request
func QueryExecutionsForRequestHandler(w http.ResponseWriter, r *http.Request) {
	// Extract the query, tabUUID, and path parameters from the URL
	tabUUID := r.URL.Query().Get("tabUUID")
	if tabUUID == "" {
		http.Error(w, "Tab UUID parameter is required", http.StatusBadRequest)
		log.Println("Missing tabUUID parameter in request")
		return
	}

	path := r.URL.Query().Get("path")
	if path == "" {
		http.Error(w, "Path parameter is required", http.StatusBadRequest)
		log.Println("Missing path parameter in request")
		return
	}

	query := r.URL.Query().Get("query")
	if query == "" {
		http.Error(w, "Query parameter is required", http.StatusBadRequest)
		log.Println("Missing query parameter in request")
		return
	}

	log.Printf("Received request with tabUUID: %s, path: %s", tabUUID, path)

	// Locate the relevant JSON file
	relevantFile, err := getRelevantJSONFile3("uploads/", tabUUID)
	if err != nil {
		http.Error(w, "Failed to find the relevant data file", http.StatusInternalServerError)
		log.Println("Error locating relevant file:", err)
		return
	}
	log.Printf("Found relevant file: %s", relevantFile)

	// Read the request data from the file
	requestData, err := readRequestDataFromFile3(relevantFile)
	if err != nil {
		http.Error(w, "Failed to load data from file", http.StatusInternalServerError)
		log.Println("Error reading data from file:", err)
		return
	}
	log.Printf("Successfully loaded %d records from the file", len(requestData))

	// Find correlation IDs related to the provided path
	var correlationIDs []string
	for _, details := range requestData {
		if details.RequestPath == path {
			correlationIDs = append(correlationIDs, details.CorrelationId)
		}
	}

	if len(correlationIDs) == 0 {
		http.Error(w, "No correlation IDs found for the given path", http.StatusNotFound)
		log.Println("No correlation IDs found for the path")
		return
	}
	log.Printf("Found %d correlation IDs", len(correlationIDs))

	// Filter the records matching the correlation IDs and exclude specific call types
	var executions []FileDetail
	for _, details := range requestData {
		if contains(correlationIDs, details.CorrelationId) && details.RequestQuery == query &&
			details.CallType != "HTTP-In-Response" && details.CallType != "HTTP-In-Request" {
			executions = append(executions, details)
		}
	}

	if len(executions) == 0 {
		http.Error(w, "No executions found for the given correlation IDs", http.StatusNotFound)
		log.Println("No matching executions found")
		return
	}
	log.Printf("Found %d matching executions", len(executions))

	// Load and render the query executions template
	tmpl, err := template.ParseFiles("template/queryExecutionForRequest.html")
	if err != nil {
		http.Error(w, "Error loading template", http.StatusInternalServerError)
		log.Println("Error loading template:", err)
		return
	}
	log.Println("Template loaded successfully")

	// Prepare the data for the template
	data := struct {
		Query      string
		Path       string
		Executions []FileDetail
	}{
		Query:      query,
		Path:       path,
		Executions: executions,
	}

	// Set the content type and execute the template
	w.Header().Set("Content-Type", "text/html")
	err = tmpl.Execute(w, data)
	if err != nil {
		http.Error(w, "Error rendering template", http.StatusInternalServerError)
		log.Println("Error rendering template:", err)
		return
	}
	log.Println("Template rendered successfully")
}

// getRelevantJSONFile3 locates the relevant JSON file based on tabUUID
func getRelevantJSONFile3(directory, tabUUID string) (string, error) {
	log.Printf("Looking for JSON file in directory: %s with tabUUID: %s", directory, tabUUID)
	files, err := os.ReadDir(directory)
	if err != nil {
		log.Println("Error reading directory:", err)
		return "", fmt.Errorf("error reading directory %s: %v", directory, err)
	}

	// Search for the file that contains the tabUUID in its name
	for _, file := range files {
		if file.IsDir() || !strings.HasSuffix(file.Name(), ".json") {
			continue
		}

		if strings.Contains(file.Name(), tabUUID) {
			log.Printf("Found file: %s", file.Name())
			return filepath.Join(directory, file.Name()), nil
		}
	}

	log.Printf("No file found for tabUUID: %s", tabUUID)
	return "", fmt.Errorf("no JSON file found for tab UUID: %s", tabUUID)
}

// readRequestDataFromFile3 reads and returns the data from the JSON file
func readRequestDataFromFile3(filename string) ([]FileDetail, error) {
	log.Printf("Opening file: %s", filename)
	file, err := os.Open(filename)
	if err != nil {
		log.Println("Error opening file:", err)
		return nil, fmt.Errorf("error opening file %s: %v", filename, err)
	}
	defer file.Close()

	var requestData []FileDetail
	err = json.NewDecoder(file).Decode(&requestData)
	if err != nil {
		log.Println("Error decoding JSON from file:", err)
		return nil, fmt.Errorf("error decoding JSON from file %s: %v", filename, err)
	}
	log.Printf("Successfully decoded %d records from file", len(requestData))
	return requestData, nil
}

// contains checks if a slice contains a specific string
func contains(slice []string, item string) bool {
	for _, v := range slice {
		if v == item {
			return true
		}
	}
	return false
}
