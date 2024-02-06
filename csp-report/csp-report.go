package main

import (
	_ "embed"
	"io"
	"strconv"

	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"
)

//go:embed index.html
var indexHTML []byte

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

type RotateWriter struct {
	lock     sync.Mutex
	filename string
	fp       *os.File
	maxSize  int64
}

// Make a new RotateWriter. Return nil if error occurs during setup.
func NewRotateWriter(filename string, maxSize int64) *RotateWriter {
	w := &RotateWriter{filename: filename, maxSize: maxSize}
	var err error
	w.fp, err = os.OpenFile(filename, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("RotateWriter: %s\n", err)
		return nil
	}
	err = w.rotate()
	if err != nil {
		log.Fatalf("RotateWriter: %s\n", err)
		w.Close()
		return nil
	}
	return w
}

// Write satisfies the io.Writer interface.
func (w *RotateWriter) Write(output []byte) (int, error) {
	w.lock.Lock()
	defer w.lock.Unlock()
	n, err := w.fp.Write(output)
	if err != nil {
		return n, err
	}
	err = w.rotate()
	return n, err
}

func (w *RotateWriter) Close() error {
	w.lock.Lock()
	defer w.lock.Unlock()
	if w.fp == nil {
		return nil
	}
	return w.fp.Close()
}

// Perform the actual act of rotating and reopening file.
func (w *RotateWriter) rotate() (err error) {
	// Check if the file size exceeds the maximum size
	info, err := w.fp.Stat()
	if err != nil {
		return err
	}

	if info.Size() < w.maxSize {
		return nil
	}

	// Close existing file if open
	if w.fp != nil {
		err = w.fp.Close()
		w.fp = nil
		if err != nil {
			return
		}
	}
	err = os.Rename(w.filename, w.filename+".old")
	if err != nil {
		return
	}
	// Create a file.
	w.fp, err = os.Create(w.filename)
	return
}

func logit(data *CSPReport) {
	enc := json.NewEncoder(cspWriter)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(data); err != nil {
		log.Printf("write log error: %s", err)
	}
}

type handler func(w http.ResponseWriter, r *http.Request)

func handle(pattern, method string, f handler) {
	http.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		defer r.Body.Close()
		if r.Method != method {
			http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
			return
		}
		const maxBodySize = 1 << 20
		r.Body = http.MaxBytesReader(w, r.Body, maxBodySize)
		f(w, r)
	})
}

func authHandle(pattern, method string, f handler) {
	handle(pattern, method, func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			http.Error(w, "Bad form", http.StatusBadRequest)
			return
		}
		if r.Form.Has("token") {
			token := r.Form.Get("token")
			if !authSuccess(token) {
				w.Header().Add("Set-Cookie", "token=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict")
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}
			w.Header().Add("Set-Cookie", "token="+hex.EncodeToString([]byte(token))+"; Path=/; HttpOnly; SameSite=Strict")
			http.Redirect(w, r, r.URL.Path, http.StatusSeeOther)
			return
		}

		cookie, err := r.Cookie("token")
		if err != nil {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		if cookie.Value != authToken {
			w.Header().Add("Set-Cookie", "token=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict")
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		f(w, r)
	})
}

var authToken = ""

func authSuccess(token string) bool {
	return authToken == hex.EncodeToString([]byte(token))
}

var cspWriter *RotateWriter

func cspReport(w http.ResponseWriter, r *http.Request) {
	var dec = json.NewDecoder(r.Body)
	var data JSONData
	if err := dec.Decode(&data); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	go logit(&data.CSPReport)
	w.WriteHeader(http.StatusOK)
}

func cspContent(w http.ResponseWriter, r *http.Request) {
	r.Header.Set("Content-Type", "text/plain; charset=utf-8")
	f, err := os.Open(cspWriter.filename)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer f.Close()
	if _, err := io.Copy(w, f); err != nil {
		log.Printf("copy log error: %s", err)
	}
}

func index(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(len(indexHTML)))
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("X-XSS-Protection", "1; mode=block")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline';")

	w.WriteHeader(http.StatusOK)
	w.Write(indexHTML)
}

func main() {
	authToken = hex.EncodeToString([]byte(os.Getenv("TOKEN")))
	cspWriter = NewRotateWriter("csp-report.log", 1<<20)

	handle("/csp-report", "POST", cspReport)
	authHandle("/", "GET", index)
	authHandle("/csp-report.log", "GET", cspContent)
	addr := os.Getenv("LISTEN")
	if addr == "" {
		addr = "localhost:9096"
	}
	log.Fatal(http.ListenAndServe(addr, nil))
}
