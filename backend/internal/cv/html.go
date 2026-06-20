package cv

import (
	"fmt"
	"html"
	"strings"
)

func renderHTML(doc CVDocument) string {
	var b strings.Builder
	b.WriteString(`<!DOCTYPE html><html><head><meta charset="utf-8"><style>
body{font-family:Georgia,serif;max-width:720px;margin:40px auto;color:#1a1a1a;line-height:1.45}
h1{font-size:26px;margin:0 0 4px}h2{font-size:14px;text-transform:uppercase;letter-spacing:.08em;color:#555;border-bottom:1px solid #ddd;padding-bottom:4px;margin:24px 0 10px}
.meta{font-size:13px;color:#444;margin-bottom:16px}.summary{font-size:14px;margin-bottom:8px}
ul{margin:0;padding-left:18px}li{margin-bottom:6px;font-size:13px}.item-title{font-weight:600}
.skills{font-size:13px}.period{color:#666;font-size:12px}
</style></head><body>`)

	b.WriteString(fmt.Sprintf("<h1>%s</h1>", html.EscapeString(doc.Headline)))
	contact := strings.Join(filterNonEmpty([]string{doc.Contact.Email, doc.Contact.Phone, doc.Contact.Location, doc.Contact.LinkedIn}), " · ")
	if contact != "" {
		b.WriteString(fmt.Sprintf(`<p class="meta">%s</p>`, html.EscapeString(contact)))
	}
	if doc.Summary != "" {
		b.WriteString(fmt.Sprintf(`<p class="summary">%s</p>`, html.EscapeString(doc.Summary)))
	}
	if len(doc.Skills) > 0 {
		b.WriteString(`<h2>Skills</h2><p class="skills">`)
		b.WriteString(html.EscapeString(strings.Join(doc.Skills, " · ")))
		b.WriteString(`</p>`)
	}
	if len(doc.Experience) > 0 {
		b.WriteString(`<h2>Experience</h2><ul>`)
		for _, item := range doc.Experience {
			b.WriteString(renderItem(item))
		}
		b.WriteString(`</ul>`)
	}
	if len(doc.Projects) > 0 {
		b.WriteString(`<h2>Projects</h2><ul>`)
		for _, item := range doc.Projects {
			b.WriteString(renderItem(item))
		}
		b.WriteString(`</ul>`)
	}
	b.WriteString(`</body></html>`)
	return b.String()
}

func renderItem(item BulletItem) string {
	title := item.Title
	if item.Company != "" {
		title = item.Company + " — " + title
	}
	line := fmt.Sprintf(`<li><span class="item-title">%s</span>`, html.EscapeString(title))
	if item.Period != "" {
		line += fmt.Sprintf(` <span class="period">(%s)</span>`, html.EscapeString(item.Period))
	}
	if item.Content != "" {
		line += fmt.Sprintf(` — %s`, html.EscapeString(item.Content))
	}
	return line + `</li>`
}

func filterNonEmpty(items []string) []string {
	out := make([]string, 0, len(items))
	for _, s := range items {
		if strings.TrimSpace(s) != "" {
			out = append(out, s)
		}
	}
	return out
}
