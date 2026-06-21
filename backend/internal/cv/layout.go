package cv

import "strings"

func projectsByCompany(projects []BulletItem) map[string][]BulletItem {
	out := map[string][]BulletItem{}
	for _, p := range projects {
		key := strings.TrimSpace(p.Company)
		if key == "" {
			key = "_ungrouped"
		}
		out[key] = append(out[key], p)
	}
	return out
}

func companyKey(company string) string {
	return strings.TrimSpace(company)
}
