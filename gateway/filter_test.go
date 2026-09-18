package main

import (
	"strings"
	"testing"
)

func TestFilterPropfindXML(t *testing.T) {
	in := `<D:multistatus xmlns:D="DAV:"><D:response><D:href>/x/</D:href></D:response><D:response><D:href>/x/photo.jpg</D:href></D:response><D:response><D:href>/x/FamilyDocs/</D:href></D:response><D:response><D:href>/x/.stfolder</D:href></D:response><D:response><D:href>/x/.temp</D:href></D:response><D:response><D:href>/x/.DS_Store</D:href></D:response><D:response><D:href>/x/._photo.jpg</D:href></D:response><D:response><D:href>/x/.stversions/</D:href></D:response><D:response><D:href>/x/.trashed-123</D:href></D:response><D:response><D:href>/x/.trash/</D:href></D:response><D:response><D:href>/x/.mace_test</D:href></D:response></D:multistatus>`

	out := string(filterPropfindXML([]byte(in)))

	for _, s := range []string{"photo.jpg", "FamilyDocs", "/x/</D:href>"} {
		if !strings.Contains(out, s) {
			t.Errorf("missing visible entry: %s", s)
		}
	}

	for _, s := range []string{".stfolder", ".temp", ".DS_Store", "._photo.jpg", ".stversions", ".trashed-123", ".trash", ".mace_test"} {
		if strings.Contains(out, s) {
			t.Errorf("hidden entry remains: %s", s)
		}
	}
}

func TestIsHiddenUIFile(t *testing.T) {
	hidden := []string{".DS_Store", "._photo.jpg", ".stfolder", ".temp", ".stversions", ".trashed-123", ".trash", ".trash-123", ".mace_test"}
	for _, name := range hidden {
		if !isHiddenUIFile(name) {
			t.Errorf("expected hidden file: %s", name)
		}
	}

	visible := []string{"photo.jpg", "FamilyDocs", "report.pdf", "notes.txt", "video.mp4"}
	for _, name := range visible {
		if isHiddenUIFile(name) {
			t.Errorf("unexpected hidden file: %s", name)
		}
	}
}
