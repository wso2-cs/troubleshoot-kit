package handlers

import (
	"html/template"
	"net/http"
)

// QueryExecutionsHandler handles requests for query executions summary.
func QueryExecutionsHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("query")
	if query == "" {
		http.Error(w, "Query parameter is required", http.StatusBadRequest)
		return
	}
	tabUUID := r.URL.Query().Get("tabUUID")
	if tabUUID == "" {
		http.Error(w, "Tab UUID parameter is required", http.StatusBadRequest)
		return
	}

	relevantFile, err := getRelevantJSONFile("uploads/", tabUUID)
	if err != nil {
		http.Error(w, "Failed to find the relevant data file", http.StatusInternalServerError)
		return
	}

	requestData, err := readRequestDataFromFile(relevantFile)
	if err != nil {
		http.Error(w, "Failed to load data from file", http.StatusInternalServerError)
		return
	}

	// Compute execution count per Correlation ID
	executionCount := make(map[string]int)
	for _, details := range requestData {
		if details.RequestQuery == query && details.CallType != "HTTP-In-Response" && details.CallType != "HTTP-In-Request" {
			executionCount[details.CorrelationId]++
		}
	}

	if len(executionCount) == 0 {
		http.Error(w, "No executions found for the given query", http.StatusNotFound)
		return
	}

	// Prepare data for rendering
	data := struct {
		Query           string
		ExecutionCounts map[string]int
		TabUUID         string
	}{
		Query:           query,
		ExecutionCounts: executionCount,
		TabUUID:         tabUUID,
	}

	tmpl, err := template.ParseFiles("template/queryExecutions.html") // Updated summary page
	if err != nil {
		http.Error(w, "Error loading template", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html")
	err = tmpl.Execute(w, data)
	if err != nil {
		http.Error(w, "Error rendering template", http.StatusInternalServerError)
		return
	}
}
