#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

rm -rf tmp/csp-report
mkdir -p tmp/csp-report
GOOS=linux GOARCH=amd64 CGO_ENABLE=0 go build -o tmp/csp-report/csp-report csp-report.go
echo "0.1.13" >tmp/csp-report/csp-report.version
cp tmp/csp-report/csp-report.version ./csp-report.version
tar -C "./tmp" -czf "./csp-report.tar.gz" .
