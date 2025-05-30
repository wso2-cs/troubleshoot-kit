package main

import (
	"Log_Anallyzer/handlers"
	"fmt"
	"net/http"
	"os"
)

func main() {
	if _, err := os.Stat("uploads"); os.IsNotExist(err) {
		os.Mkdir("uploads", os.ModePerm)
	}

	// Redirect root to /upload
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Println("Redirecting from / to /upload")
		http.Redirect(w, r, "/upload", http.StatusSeeOther)
	})

	http.HandleFunc("/upload", handlers.UploadHandler)
	http.HandleFunc("/request-details", handlers.RequestDetailsHandler)
	http.HandleFunc("/queryExecutions", handlers.QueryExecutionsHandler)
	http.HandleFunc("/correlationDetails", handlers.CorrelationDetailsHandler)
	http.HandleFunc("/queryExecutionsForRequestPath", handlers.QueryExecutionsForRequestHandler)
	http.HandleFunc("/queryDetails", handlers.QueryDetailsHandler)

	fmt.Println("Server started on http://localhost:8080/upload")
	http.ListenAndServe(":8080", nil)
}
