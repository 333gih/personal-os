package cv

import (
	"fmt"
	"html"
	"strings"
)

func renderHTML(doc CVDocument) string {
	NormalizeDocument(&doc)
	name, role := splitHeadline(doc.Headline)
	var b strings.Builder
	b.WriteString(`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>
:root{--accent:#1a365d;--muted:#5a6472;--line:#111827}
*{box-sizing:border-box}
body{font-family:"Segoe UI",system-ui,-apple-system,sans-serif;max-width:920px;margin:24px auto;padding:0 20px 32px;color:#111827;line-height:1.45;background:#fff}
.header{margin-bottom:10px}
.name{font-size:1.65rem;font-weight:800;color:var(--accent);margin:0;letter-spacing:.02em;text-transform:uppercase}
.role{font-size:.95rem;color:#374151;margin:4px 0 0;font-weight:500}
.contact-row{display:flex;flex-wrap:wrap;gap:6px 18px;font-size:.78rem;color:var(--muted);margin:10px 0 0}
.contact-row span{white-space:nowrap}
.layout{display:grid;grid-template-columns:32% 68%;gap:22px;margin-top:8px}
.col-left,.col-right{min-width:0}
h2{font-size:.68rem;font-weight:800;text-transform:uppercase;letter-spacing:.1em;color:#111;margin:0 0 6px;padding-bottom:5px;border-bottom:2px solid var(--line)}
.section{margin-bottom:16px}
.summary{font-size:.82rem;margin:0;color:#1f2937}
.skill-group{margin-bottom:8px;font-size:.78rem}
.skill-group .cat{font-weight:700;color:#111;display:block;margin-bottom:2px}
.skill-group .items{color:#374151;line-height:1.4}
.edu-block,.cert-block{margin-bottom:10px;font-size:.78rem}
.edu-block .school{font-weight:700;color:#111}
.edu-block .meta{color:var(--muted);font-style:italic}
.block{margin-bottom:12px}
.company{font-weight:800;color:#111;font-size:.82rem;margin:0 0 2px;text-transform:uppercase}
.row{display:flex;justify-content:space-between;gap:10px;align-items:baseline;margin:0 0 3px}
.row .title{font-weight:700;font-size:.8rem;color:#111}
.row .period{font-size:.74rem;color:var(--muted);font-style:italic;white-space:nowrap}
ul{margin:0;padding:0 0 0 1rem}
li{margin-bottom:3px;font-size:.78rem;color:#374151}
@media print{
  body{margin:0;max-width:none;padding:8mm}
  .layout{gap:14px}
  @page{size:A4;margin:8mm}
  .section{margin-bottom:10px}
  h2{font-size:.62rem;margin-bottom:4px;padding-bottom:3px}
  .summary,.skill-group,.edu-block,.cert-block,.block{font-size:.72rem}
  li{font-size:.72rem;margin-bottom:2px}
  .name{font-size:1.45rem}
  .role{font-size:.88rem}
  .contact-row{font-size:.72rem}
}
</style></head><body>`)

	b.WriteString(`<div class="header">`)
	b.WriteString(fmt.Sprintf(`<h1 class="name">%s</h1>`, html.EscapeString(strings.ToUpper(name))))
	if role != "" {
		b.WriteString(fmt.Sprintf(`<p class="role">%s</p>`, html.EscapeString(role)))
	}
	b.WriteString(renderContactRow(doc.Contact))
	b.WriteString(`</div>`)

	b.WriteString(`<div class="layout">`)
	b.WriteString(`<div class="col-left">`)
	if doc.Summary != "" {
		b.WriteString(`<div class="section"><h2>Summary</h2>`)
		b.WriteString(fmt.Sprintf(`<p class="summary">%s</p></div>`, html.EscapeString(doc.Summary)))
	}
	b.WriteString(renderEducationHTML(doc))
	b.WriteString(renderSkillGroupsHTML(doc))
	b.WriteString(renderAchievementsHTML(doc))
	b.WriteString(renderCertificatesHTML(doc))
	b.WriteString(`</div>`)

	b.WriteString(`<div class="col-right">`)
	if len(doc.Experience) > 0 {
		b.WriteString(`<div class="section"><h2>Experiences</h2>`)
		grouped := projectsByCompany(doc.Projects)
		for _, item := range doc.Experience {
			b.WriteString(renderHTMLBlock(item, true))
			for _, p := range grouped[companyKey(item.Company)] {
				b.WriteString(renderHTMLProjectBlock(p))
			}
		}
		if orphans := grouped["_ungrouped"]; len(orphans) > 0 {
			for _, p := range orphans {
				b.WriteString(renderHTMLProjectBlock(p))
			}
		}
		b.WriteString(`</div>`)
	}
	b.WriteString(`</div></div>`)

	b.WriteString(`</body></html>`)
	return b.String()
}

func renderContactRow(c Contact) string {
	type pair struct {
		label string
		value string
	}
	items := []pair{
		{"✉", c.Email},
		{"☎", c.Phone},
		{"📍", c.Location},
		{"in", c.LinkedIn},
		{"gh", c.GitHub},
	}
	var parts []string
	for _, p := range items {
		if strings.TrimSpace(p.value) == "" {
			continue
		}
		parts = append(parts, fmt.Sprintf(`<span>%s %s</span>`, html.EscapeString(p.label), html.EscapeString(strings.TrimSpace(p.value))))
	}
	if len(parts) == 0 {
		return ""
	}
	return `<div class="contact-row">` + strings.Join(parts, "") + `</div>`
}

func renderSkillGroupsHTML(doc CVDocument) string {
	if len(doc.SkillGroups) == 0 && len(doc.Skills) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString(`<div class="section"><h2>Skills</h2>`)
	if len(doc.SkillGroups) > 0 {
		for _, g := range doc.SkillGroups {
			if len(g.Items) == 0 {
				continue
			}
			b.WriteString(`<div class="skill-group">`)
			b.WriteString(fmt.Sprintf(`<span class="cat">%s:</span>`, html.EscapeString(g.Category)))
			b.WriteString(fmt.Sprintf(`<span class="items">%s</span>`, html.EscapeString(strings.Join(g.Items, ", "))))
			b.WriteString(`</div>`)
		}
	} else {
		b.WriteString(fmt.Sprintf(`<p class="summary">%s</p>`, html.EscapeString(formatSkillLine(doc.Skills))))
	}
	b.WriteString(`</div>`)
	return b.String()
}

func renderCertificatesHTML(doc CVDocument) string {
	if len(doc.Certificates) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString(`<div class="section"><h2>Certificates</h2>`)
	for _, c := range doc.Certificates {
		b.WriteString(`<div class="cert-block">`)
		line := c.Title
		if c.Issuer != "" {
			line += " — " + c.Issuer
		}
		b.WriteString(fmt.Sprintf(`<div>%s</div>`, html.EscapeString(line)))
		if c.Period != "" {
			b.WriteString(fmt.Sprintf(`<div class="meta">%s</div>`, html.EscapeString(c.Period)))
		}
		b.WriteString(`</div>`)
	}
	b.WriteString(`</div>`)
	return b.String()
}

func renderEducationHTML(doc CVDocument) string {
	if len(doc.Education) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString(`<div class="section"><h2>Educations</h2>`)
	for _, e := range doc.Education {
		b.WriteString(`<div class="edu-block">`)
		meta := filterNonEmpty([]string{e.Period})
		title := e.School
		if e.Degree != "" {
			title = e.School
		}
		b.WriteString(fmt.Sprintf(`<div class="school">%s</div>`, html.EscapeString(title)))
		if len(meta) > 0 {
			b.WriteString(fmt.Sprintf(`<div class="meta">%s</div>`, html.EscapeString(strings.Join(meta, " · "))))
		}
		if e.Content != "" {
			b.WriteString(fmt.Sprintf(`<div>%s</div>`, html.EscapeString(e.Content)))
		}
		b.WriteString(`</div>`)
	}
	b.WriteString(`</div>`)
	return b.String()
}

func renderAchievementsHTML(doc CVDocument) string {
	if len(doc.Achievements) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString(`<div class="section"><h2>Achievements</h2><ul>`)
	for _, a := range doc.Achievements {
		if strings.TrimSpace(a.Content) == "" {
			continue
		}
		b.WriteString(fmt.Sprintf(`<li>%s</li>`, html.EscapeString(strings.TrimSpace(a.Content))))
	}
	b.WriteString(`</ul></div>`)
	return b.String()
}

func renderHTMLProjectBlock(item BulletItem) string {
	var b strings.Builder
	b.WriteString(`<div class="block">`)
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
