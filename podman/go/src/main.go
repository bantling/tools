package main

import (
	"net/http"
	"os"
)

func main() {
	http.ListenAndServe(":8000", http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			if (r.Method == "GET") && (r.URL.Path == "/quit") {
				os.Exit(0)
			}
			w.Write([]byte("Hello, World: " + r.URL.Path + "\n"))
		},
	))
}
