package main

import (
	_ "embed"

	"testing"
)

//go:embed example.json
var data []byte

func TestCSPBodyUnmarshal(t *testing.T) {
	b, err := unmarshalBody(data)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range b {
		if v.DocumentURI == "" {
			t.Fatalf("%+v", v)
		}
	}
}
