package main

import (
	"encoding/xml"
	"html/template"
	"io"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"path"
	"sort"
	"strconv"
	"strings"
)

const listenAddr = "127.0.0.1:6066"

type Entry struct {
	Name string
	URL  string
	Dir  bool
	Size string
	Icon string
}

type PageData struct {
	Path      string
	Entries   []Entry
	ParentURL string
	HasParent bool
}

type propStat struct {
	Prop struct {
		ResourceType struct {
			Collection *struct{} `xml:"collection"`
		} `xml:"resourcetype"`
		ContentLength string `xml:"getcontentlength"`
	} `xml:"prop"`
}

type davResponse struct {
	Href     string     `xml:"href"`
	PropStat []propStat `xml:"propstat"`
}

type multiStatus struct {
	Responses []davResponse `xml:"response"`
}

var pageTemplate = template.Must(template.New("index").Parse(`
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MyCloud</title>
<style>
:root { --bg:#f5f5f7; --card:#fff; --text:#222; --muted:#777; --border:#e8e8eb; --hover:#f7f7f9; }
* { box-sizing:border-box; }
body { font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif; margin:0; background:var(--bg); color:var(--text); }
header { padding:16px 24px; background:var(--card); border-bottom:1px solid var(--border); }
.header-inner { max-width:1000px; margin:0 auto; }
.brand { font-size:22px; font-weight:700; }
main { max-width:1000px; margin:24px auto; padding:0 16px; }
.toolbar { display:flex; gap:8px; margin-bottom:14px; }
.button { display:inline-flex; align-items:center; gap:6px; padding:8px 12px; border:1px solid var(--border); border-radius:8px; background:var(--card); color:var(--text); text-decoration:none; font-size:14px; }
.button:hover { background:var(--hover); text-decoration:none; }
.button.disabled { color:#aaa; pointer-events:none; }
.breadcrumb { padding:12px 16px; background:var(--card); border:1px solid var(--border); border-radius:10px; margin-bottom:14px; color:var(--muted); overflow-wrap:anywhere; }
table { width:100%; border-collapse:separate; border-spacing:0; background:var(--card); border:1px solid var(--border); border-radius:10px; overflow:hidden; }
th { padding:10px 16px; text-align:left; font-size:12px; font-weight:600; color:var(--muted); border-bottom:1px solid var(--border); }
td { padding:12px 16px; border-bottom:1px solid var(--border); }
tr:last-child td { border-bottom:0; }
tr:hover td { background:var(--hover); }
.name-cell { display:flex; align-items:center; gap:10px; min-width:0; }
.name-cell a { color:var(--text); text-decoration:none; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.name-cell a:hover { text-decoration:underline; }
.icon { width:28px; flex:0 0 28px; font-size:20px; text-align:center; }
.size { width:150px; color:var(--muted); font-size:13px; text-align:right; }
.empty { padding:28px 16px; text-align:center; color:var(--muted); }
@media (max-width:600px) { main{margin:14px auto;} header{padding:14px 16px;} th.size,td.size{display:none;} td{padding:11px 12px;} }
</style>
</head>
<body>
<header><div class="header-inner"><div class="brand">MyCloud</div></div></header>
<main>
<div class="toolbar">
<a class="button" href="/">⌂ Home</a>
{{if .HasParent}}<a class="button" href="{{.ParentURL}}">← Back</a>{{else}}<span class="button disabled">← Back</span>{{end}}
</div>
<div class="breadcrumb">{{.Path}}</div>
<table>
<thead><tr><th>Name</th><th class="size">Size</th></tr></thead>
<tbody>
{{range .Entries}}
<tr><td><div class="name-cell"><span class="icon">{{.Icon}}</span><a href="{{.URL}}">{{.Name}}</a></div></td><td class="size">{{.Size}}</td></tr>
{{else}}
<tr><td colspan="2" class="empty">Folder is empty</td></tr>
{{end}}
</tbody>
</table>
</main>
</body>
</html>
`))

func main() {
	webdavURL := os.Getenv("WEBDAV_URL")
	if webdavURL == "" {
		webdavURL = "http://127.0.0.1:6065"
	}

	target, err := url.Parse(webdavURL)
	if err != nil {
		log.Fatal(err)
	}

	proxy := httputil.NewSingleHostReverseProxy(target)

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			proxy.ServeHTTP(w, r)
			return
		}

		isDir, entries := inspectDirectory(webdavURL, r)

		if !isDir {
			proxy.ServeHTTP(w, r)
			return
		}

		renderDirectory(w, r.URL.Path, entries)
	})

	server := &http.Server{
		Addr:    listenAddr,
		Handler: handler,
	}

	log.Printf("webdav-gw listening on %s", listenAddr)
	log.Printf("WebDAV upstream: %s", webdavURL)
	log.Fatal(server.ListenAndServe())
}

func inspectDirectory(webdavURL string, r *http.Request) (bool, []Entry) {
	req, err := http.NewRequest(
		http.MethodGet,
		webdavURL+r.URL.RequestURI(),
		nil,
	)
	if err != nil {
		return false, nil
	}

	copyAuthorization(r, req)

	req.Method = "PROPFIND"
	req.Header.Set("Depth", "1")
	req.Header.Set("Content-Type", "application/xml")

	client := &http.Client{}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("PROPFIND error: %v", err)
		return false, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusMultiStatus {
		log.Printf("PROPFIND %s returned HTTP %d", r.URL.Path, resp.StatusCode)
		return false, nil
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("PROPFIND read error: %v", err)
		return false, nil
	}

	return parseDirectory(r.URL.Path, body)
}

func copyAuthorization(src, dst *http.Request) {
	if value := src.Header.Get("Authorization"); value != "" {
		dst.Header.Set("Authorization", value)
	}
}

func parseDirectory(currentPath string, body []byte) (bool, []Entry) {
	var ms multiStatus

	if err := xml.Unmarshal(body, &ms); err != nil {
		log.Printf("XML parse error: %v", err)
		return false, nil
	}

	currentPath = normalizePath(currentPath)
	resourceIsDir := false
	var entries []Entry

	for _, response := range ms.Responses {
		href := normalizePath(response.Href)

		if href == currentPath {
			for _, propstat := range response.PropStat {
				if propstat.Prop.ResourceType.Collection != nil {
					resourceIsDir = true
					break
				}
			}
			continue
		}

		name := path.Base(href)
		if name == "." || name == "/" || name == "" {
			continue
		}
		if isHiddenUIFile(name) {
			continue
		}

		isDir := false
		size := ""
		for _, propstat := range response.PropStat {
			if propstat.Prop.ResourceType.Collection != nil {
				isDir = true
			}
			if !isDir && propstat.Prop.ContentLength != "" {
				size = formatSize(propstat.Prop.ContentLength)
			}
		}

		entryURL := href
		if isDir && !strings.HasSuffix(entryURL, "/") {
			entryURL += "/"
		}

		entries = append(entries, Entry{
			Name: name,
			URL:  entryURL,
			Dir:  isDir,
			Size: size,
			Icon: fileIcon(name, isDir),
		})
	}

	sort.Slice(entries, func(i, j int) bool {
		if entries[i].Dir != entries[j].Dir {
			return entries[i].Dir
		}
		return strings.ToLower(entries[i].Name) < strings.ToLower(entries[j].Name)
	})

	return resourceIsDir, entries
}

func isHiddenUIFile(name string) bool {
	if name == ".DS_Store" ||
		name == ".stfolder" ||
		name == ".temp" ||
		name == ".stversions" {
		return true
	}

	return strings.HasPrefix(name, "._") ||
		strings.HasPrefix(name, ".trashed-") ||
		strings.HasPrefix(name, ".trash") ||
		strings.HasPrefix(name, ".mace_")
}

func fileIcon(name string, isDir bool) string {
	if isDir {
		return "📁"
	}

	ext := strings.ToLower(path.Ext(name))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".heic", ".heif":
		return "🖼️"
	case ".mp4", ".mkv", ".mov", ".avi", ".webm", ".m4v", ".3gp":
		return "🎬"
	case ".mp3", ".m4a", ".wav", ".flac", ".aac", ".ogg":
		return "🎵"
	case ".pdf", ".doc", ".docx", ".txt", ".rtf":
		return "📄"
	case ".xls", ".xlsx", ".csv":
		return "📊"
	case ".ppt", ".pptx":
		return "📑"
	case ".zip", ".rar", ".7z", ".tar", ".gz":
		return "📦"
	default:
		return "📄"
	}
}

func formatSize(value string) string {
	n, err := strconv.ParseInt(value, 10, 64)
	if err != nil || n < 0 {
		return ""
	}
	if n < 1024 {
		return strconv.FormatInt(n, 10) + " B"
	}
	f := float64(n)
	for _, unit := range []string{"KB", "MB", "GB", "TB"} {
		f /= 1024
		if f < 1024 {
			return strconv.FormatFloat(f, 'f', 1, 64) + " " + unit
		}
	}
	return strconv.FormatFloat(f, 'f', 1, 64) + " PB"
}

func normalizePath(value string) string {
	if value == "" {
		return "/"
	}

	if parsed, err := url.Parse(value); err == nil && parsed.Path != "" {
		value = parsed.Path
	}

	if !strings.HasPrefix(value, "/") {
		value = "/" + value
	}

	value = path.Clean(value)
	if value == "." {
		value = "/"
	}

	return value
}

func renderDirectory(w http.ResponseWriter, currentPath string, entries []Entry) {
	currentPath = normalizePath(currentPath)
	parentURL := path.Dir(currentPath)
	if parentURL == "." {
		parentURL = "/"
	}
	if parentURL != "/" && !strings.HasSuffix(parentURL, "/") {
		parentURL += "/"
	}

	data := PageData{
		Path:      currentPath,
		Entries:   entries,
		ParentURL: parentURL,
		HasParent: currentPath != "/",
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := pageTemplate.Execute(w, data); err != nil {
		http.Error(w, "template error", http.StatusInternalServerError)
	}
}
