package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

type JSONData struct {
	CSPReport `json:"csp-report"`
}

// CSPReport 是 CSP 报告的结构体，你可以根据需要增减字段
type CSPReport struct {
	BlockedURI         string `json:"blocked-uri"`
	DocumentURI        string `json:"document-uri"`
	EffectiveDirective string `json:"effective-directive"`
	OriginalPolicy     string `json:"original-policy"`
	Referrer           string `json:"referrer"`
	ViolatedDirective  string `json:"violated-directive"`
}

func cspReport(w http.ResponseWriter, r *http.Request) {
	var dec = json.NewDecoder(r.Body)
	var data JSONData
	if err := dec.Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	w.WriteHeader(http.StatusOK)
}

type handler func(w http.ResponseWriter, r *http.Request)

func handle(pattern, method string, f handler) {
	http.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		if r.Method != method {
			http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
			return
		}
		r.Header.Get("Content-Length")
	})
}

func main() {
	handle("/csp-report", "POST", cspReport)
	addr := os.Getenv("LISTEN")
	if addr == "" {
		addr = ":9096"
	}
	log.Fatal(http.ListenAndServe(addr, nil))
}
