package main

import (
	_ "embed"

	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"
)

//go:embed index.html
var indexHTML []byte

//go:embed auth.html
var authHTML []byte

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
	log.Printf("rotate a new file")
	return
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func NewLoggingResponseWriter(w http.ResponseWriter) *loggingResponseWriter {
	return &loggingResponseWriter{w, http.StatusOK}
}

func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

type handler func(w http.ResponseWriter, r *http.Request)

func handle(pattern, method string, auth bool, f handler) {
	mf := func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}
		f(w, r)
	}
	http.HandleFunc(pattern, func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		lw := NewLoggingResponseWriter(w)
		w = lw
		defer func() {
			log.Printf("%s %s %d %s", r.Method, r.URL.Path, lw.statusCode, time.Since(startTime))
		}()
		defer r.Body.Close()
		const maxBodySize = 1 << 20
		r.Body = http.MaxBytesReader(w, r.Body, maxBodySize)
		if auth {
			authMiddleware(lw, r, mf)
		} else {
			mf(lw, r)
		}
	})
}

func authMiddleware(w http.ResponseWriter, r *http.Request, f handler) {
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
		w.Header().Add("Set-Cookie", "token=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict")
		sendHTML(w, authHTML)
		return
	}
	if cookie.Value != authToken {
		w.Header().Add("Set-Cookie", "token=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict")
		sendHTML(w, authHTML)
		return
	}
	f(w, r)
}

var authToken = ""

func authSuccess(token string) bool {
	return authToken == hex.EncodeToString([]byte(token))
}

var cspWriter *RotateWriter

func logit(data []CSPReport) {
	var n int
	for _, v := range data {
		enc := json.NewEncoder(cspWriter)
		enc.SetEscapeHTML(false)
		if err := enc.Encode(v); err != nil {
			log.Printf("write log error: %s", err)
		} else {
			n++
		}
	}
	log.Printf("write %d report logs", n)
}

type reportURIBody struct {
	CSPReport *CSPReport `json:"csp-report"`
}

type reportTOBody []reportTOData

type reportTOData struct {
	Body CSPReport `json:"body"`
}

// CSPReport 是 CSP 报告的结构体，你可以根据需要增减字段
type CSPReport struct {
	BlockedURI         string `json:"blocked-uri"`
	DocumentURI        string `json:"document-uri"`
	EffectiveDirective string `json:"effective-directive"`
	OriginalPolicy     string `json:"original-policy"`
	Referrer           string `json:"referrer"`
	Disposition        string `json:"disposition"`
}

func getNotEmpty(m map[string]interface{}, keys ...string) string {
	for _, k := range keys {
		v, ok := m[k]
		if !ok {
			continue
		}
		if s, ok := v.(string); ok && s != "" {
			return s
		}
	}
	return ""
}

func (s *CSPReport) UnmarshalJSON(data []byte) error {
	m := map[string]interface{}{}
	if err := json.Unmarshal(data, &m); err != nil {
		return err
	}
	s.BlockedURI = getNotEmpty(m, "blocked-uri", "blockedURL")
	s.DocumentURI = getNotEmpty(m, "document-uri", "documentURL")
	s.EffectiveDirective = getNotEmpty(m, "effective-directive", "effectiveDirective")
	s.OriginalPolicy = getNotEmpty(m, "original-policy", "originalPolicy")
	s.Referrer = getNotEmpty(m, "referrer")
	s.Disposition = getNotEmpty(m, "disposition")
	return nil
}

func unmarshalBody(b []byte) ([]CSPReport, error) {
	var a reportURIBody
	err := json.Unmarshal(b, &a)
	if err == nil && a.CSPReport != nil {
		return []CSPReport{*a.CSPReport}, nil
	}
	var c reportTOBody
	if err := json.Unmarshal(b, &c); err != nil {
		return nil, err
	}
	var reports []CSPReport
	for _, v := range c {
		reports = append(reports, v.Body)
	}
	return reports, nil
}

func cspReport(w http.ResponseWriter, r *http.Request) {
	b, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if debugMode {
		log.Printf("Content-Type=%s, Body=%s", r.Header.Get("Content-Type"), string(b))
	}
	reports, err := unmarshalBody(b)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	go logit(reports)
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

func sendHTML(w http.ResponseWriter, data []byte) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(len(data)))
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("X-XSS-Protection", "1; mode=block")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline';")
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

func index(w http.ResponseWriter, r *http.Request) {
	sendHTML(w, indexHTML)
}

func cspTest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, `
<html>
<body>
<p>load https://www.example.com/a.js</p>
<script src="https://www.example.com/a.js"></script>
</body>
</html>
	`)
}

var debugMode bool

func main() {
	tkn := os.Getenv("TOKEN")
	if tkn == "" {
		log.Fatalf("env TOKEN not set")
	}
	authToken = hex.EncodeToString([]byte(tkn))
	length, _ := strconv.Atoi(os.Getenv("MAX_LOG_SIZE"))
	if length < 1<<20 {
		length = 1 << 20
	}
	cspWriter = NewRotateWriter("csp-report.log", int64(length))
	debugMode = os.Getenv("DEBUG") == "true"

	handle("/csp-report", "POST", false, cspReport)
	handle("/csp-test", "GET", false, cspTest)
	handle("/", "GET", true, index)
	handle("/csp-report.log", "GET", true, cspContent)
	addr := os.Getenv("LISTEN")
	if addr == "" {
		addr = "localhost:9096"
	}
	log.Printf("server listen on: %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
