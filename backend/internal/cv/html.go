package cv

import (
	"fmt"
	"html"
	"strings"
)

func renderHTML(doc CVDocument) string {
	name, role := splitHeadline(doc.Headline)
	var b strings.Builder
	b.WriteString(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>
:root{--accent:#1a365d;--muted:#5a6472;--line:#d2d6dc}
*{box-sizing:border-box}
body{font-family:"Segoe UI",system-ui,-apple-system,sans-serif;max-width:780px;margin:32px auto;padding:0 24px 40px;color:#111827;line-height:1.5;background:#fff}
.name{font-size:1.75rem;font-weight:700;color:var(--accent);margin:0 0 2px;letter-spacing:-.02em}
.role{font-size:.95rem;color:var(--muted);margin:0 0 10px}
.rule{height:3px;background:var(--accent);border:0;margin:0 0 12px}
.meta{font-size:.85rem;color:var(--muted);margin:0 0 4px}
h2{font-size:.72rem;font-weight:700;text-transform:uppercase;letter-spacing:.12em;color:var(--accent);margin:22px 0 8px;padding-bottom:6px;border-bottom:1px solid var(--line)}
.summary{font-size:.92rem;margin:0 0 4px}
.skills{font-size:.88rem;color:#1f2937}
.block{margin-bottom:14px}
.company{font-weight:700;color:var(--accent);font-size:.95rem;margin:0 0 2px}
.row{display:flex;justify-content:space-between;gap:12px;align-items:baseline;margin:0 0 4px}
.row .title{font-weight:600;font-size:.9rem}
.row .period{font-size:.82rem;color:var(--muted);font-style:italic;white-space:nowrap}
ul{margin:0;padding:0 0 0 1.1rem}
li{margin-bottom:4px;font-size:.88rem}
@media print{body{margin:0;max-width:none;padding:16mm}}
</style></head><body>`)

	b.WriteString(fmt.Sprintf(`<h1 class="name">%s</h1>`, html.EscapeString(name)))
	if role != "" {
		b.WriteString(fmt.Sprintf(`<p class="role">%s</p>`, html.EscapeString(role)))
	}
	b.WriteString(`<hr class="rule">`)

	contact := strings.Join(filterNonEmpty([]string{doc.Contact.Email, doc.Contact.Phone, doc.Contact.Location, doc.Contact.LinkedIn}), " · ")
	if contact != "" {
		b.WriteString(fmt.Sprintf(`<p class="meta">%s</p>`, html.EscapeString(contact)))
	}
	if doc.Summary != "" {
		b.WriteString(`<h2>Summary</h2>`)
		b.WriteString(fmt.Sprintf(`<p class="summary">%s</p>`, html.EscapeString(doc.Summary)))
	}
	if len(doc.Skills) > 0 {
		b.WriteString(`<h2>Skills</h2>`)
		b.WriteString(fmt.Sprintf(`<p class="skills">%s</p>`, html.EscapeString(formatSkillLine(doc.Skills))))
	}
	if len(doc.Experience) > 0 {
		b.WriteString(`<h2>Experience</h2>`)
		for _, item := range doc.Experience {
			b.WriteString(renderHTMLBlock(item, true))
		}
	}
	if len(doc.Projects) > 0 {
		b.WriteString(`<h2>Projects</h2>`)
		for _, item := range doc.Projects {
			b.WriteString(renderHTMLBlock(item, false))
		}
	}
	b.WriteString(`</body></html>`)
	return b.String()
}

func renderHTMLBlock(item BulletItem, showCompany bool) string {
	var b strings.Builder
	b.WriteString(`<div class="block">`)
	if showCompany && strings.TrimSpace(item.Company) != "" {
		b.WriteString(fmt.Sprintf(`<p class="company">%s</p>`, html.EscapeString(strings.TrimSpace(item.Company))))
	}
	title := strings.TrimSpace(item.Title)
	period := strings.TrimSpace(item.Period)
	if title != "" || period != "" {
		b.WriteString(`<div class="row">`)
		b.WriteString(fmt.Sprintf(`<span class="title">%s</span>`, html.EscapeString(title)))
		if period != "" {
			b.WriteString(fmt.Sprintf(`<span class="period">%s</span>`, html.EscapeString(period)))
		}
		b.WriteString(`</div>`)
	}
	bullets := splitBullets(item.Content)
	if len(bullets) > 0 {
		b.WriteString(`<ul>`)
		for _, line := range bullets {
			b.WriteString(fmt.Sprintf(`<li>%s</li>`, html.EscapeString(line)))
		}
		b.WriteString(`</ul>`)
	}
	b.WriteString(`</div>`)
	return b.String()
}

func filterNonEmpty(items []string) []string {
	out := make([]string, 0, len(items))
	for _, s := range items {
		if strings.TrimSpace(s) != "" {
			out = append(out, strings.TrimSpace(s))
		}
	}
	return out
}
