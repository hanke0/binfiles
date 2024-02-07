package main

import (
	_ "embed"

	"testing"
)

//go:embed example.json
var data []byte

//go:embed example1.json
var data1 []byte

func testCSPBodyUnmarshal1(t *testing.T, data []byte) {
	t.Helper()
	b, err := unmarshalBody(data)
	if err != nil {
		t.Fatal(err)
	}
	for _, v := range b {
		if v.DocumentURI == "" {
			t.Fatalf("%+v", v)
		}
		if v.Disposition == "" {
			t.Fatalf("%+v", v)
		}
	}
}
func TestCSPBodyUnmarshal(t *testing.T) {
	testCSPBodyUnmarshal1(t, data)
	testCSPBodyUnmarshal1(t, data1)
}
