package handlers

import (
	"html/template"
	"net/http"
)

// QueryDetailsHandler fetches and displays queries for a specific correlation ID and query.
func QueryDetailsHandler(w http.ResponseWriter, r *http.Request) {
	correlationId := r.URL.Query().Get("correlationId")
	tabUUID := r.URL.Query().Get("tabUUID")
	query := r.URL.Query().Get("query")

	if correlationId == "" {
		http.Error(w, "Correlation ID is required", http.StatusBadRequest)
		return
	}
	if tabUUID == "" {
		http.Error(w, "Tab UUID is required", http.StatusBadRequest)
		return
	}
	if query == "" {
		http.Error(w, "Query is required", http.StatusBadRequest)
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

	// Collect only queries that match the correlation ID and the query
	var queries []FileDetail
	for _, details := range requestData {
		if details.CorrelationId == correlationId && details.RequestQuery == query {
			queries = append(queries, details)
		}
	}

	if len(queries) == 0 {
		http.Error(w, "No queries found for the given Correlation ID and Query", http.StatusNotFound)
		return
	}

	// Prepare data for rendering
	data := struct {
		CorrelationId string
		Query         string
		Queries       []FileDetail
	}{
		CorrelationId: correlationId,
		Query:         query,
		Queries:       queries,
	}

	tmpl, err := template.ParseFiles("template/queryDetails.html")
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
