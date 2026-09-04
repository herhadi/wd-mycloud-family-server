package main

import (
	"strings"
	"testing"
)

func TestFilterPropfindXML(t *testing.T) {
	in := `<D:multistatus xmlns:D="DAV:"><D:response><D:href>/x/</D:href></D:response><D:response><D:href>/x/photo.jpg</D:href></D:response><D:response><D:href>/x/.stfolder</D:href></D:response><D:response><D:href>/x/.temp</D:href></D:response></D:multistatus>`

	out := string(filterPropfindXML([]byte(in)))

	for _, s := range []string{"photo.jpg", "/x/</D:href>"} {
		if !strings.Contains(out, s) {
			t.Errorf("missing visible entry: %s", s)
		}
	}

	for _, s := range []string{".stfolder", ".temp"} {
		if strings.Contains(out, s) {
			t.Errorf("hidden entry remains: %s", s)
		}
	}
}
