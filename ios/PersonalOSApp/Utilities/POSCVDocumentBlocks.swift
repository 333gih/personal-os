import Foundation

enum POSCVDocumentBlocks {
    /// Client-side fallback when API templates have empty blocks (mirrors backend DocumentToBlocks).
    static func build(from doc: POSCVDocument) -> [POSCVBlock] {
        var blocks: [POSCVBlock] = []
        var order = 0

        func add(_ block: POSCVBlock) {
            var b = block
            b.order = order
            order += 1
            blocks.append(b)
        }

        let summaryText: String = {
            if !doc.summary.isEmpty && !doc.headline.isEmpty && !doc.summary.contains(doc.headline) {
                return doc.headline + "\n" + doc.summary
            }
            if !doc.summary.isEmpty { return doc.summary }
            return doc.headline
        }()
        if !summaryText.isEmpty {
            add(POSCVBlock(id: "summary", type: "summary", order: 0, enabled: true, content: summaryText))
        }

        if let contact = doc.contact {
            let parts = [contact.email, contact.phone, contact.location, contact.linkedin, contact.github]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !parts.isEmpty {
                let overrides = POSCVBlockOverrides(
                    email: contact.email, phone: contact.phone, location: contact.location,
                    linkedin: contact.linkedin, github: contact.github
                )
                add(POSCVBlock(id: "contact", type: "contact", order: 0, enabled: true, content: parts.joined(separator: " · "), overrides: overrides))
            }
        }

        if let groups = doc.skillGroups, !groups.isEmpty {
            var overrides: POSCVBlockOverrides?
            if let stack = doc.primaryStack, !stack.isEmpty {
                overrides = POSCVBlockOverrides(title: nil, company: nil, period: nil, highlightStack: nil, skillItems: stack)
            }
            add(POSCVBlock(
                id: "skills", type: "skills", order: 0, enabled: true,
                content: nil, overrides: overrides, skillGroups: groups
            ))
        }

        doc.achievements?.enumerated().forEach { i, item in
            add(POSCVBlock(id: "achievement-\(i)", type: "achievements", order: 0, enabled: true, content: item.content))
        }

        doc.education?.enumerated().forEach { i, item in
            var text = item.school
            if let degree = item.degree, !degree.isEmpty { text += " · \(degree)" }
            if let period = item.period, !period.isEmpty { text += " (\(period))" }
            if let content = item.content, !content.isEmpty { text += "\n\(content)" }
            add(POSCVBlock(id: "education-\(i)", type: "education", order: 0, enabled: true, content: text))
        }

        doc.certificates?.enumerated().forEach { i, item in
            let text = [item.title, item.issuer].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            add(POSCVBlock(id: "cert-\(i)", type: "certificates", order: 0, enabled: true, content: text))
        }

        doc.experience?.forEach { item in
            let id = item.id ?? UUID().uuidString
            add(POSCVBlock(
                id: id, type: "experience", order: 0, enabled: true,
                sourceEntityID: item.id, content: item.content,
                overrides: POSCVBlockOverrides(title: item.title, company: item.company, period: item.period)
            ))
        }

        doc.projects?.forEach { item in
            let id = item.id ?? UUID().uuidString
            let (stack, cleaned) = extractTechStack(from: item.content)
            add(POSCVBlock(
                id: id, type: "project", order: 0, enabled: true,
                sourceEntityID: item.id, content: cleaned,
                overrides: POSCVBlockOverrides(
                    title: item.title, company: item.company, period: item.period,
                    highlightStack: stack.isEmpty ? nil : stack
                )
            ))
        }

        return blocks.enumerated().map { index, block in
            var b = block
            b.order = index
            return b
        }
    }

    private static func extractTechStack(from content: String) -> ([String], String) {
        guard let range = content.range(of: #"(?m)^\s*Tech:\s*(.+?)$"#, options: .regularExpression) else {
            return ([], content)
        }
        let line = String(content[range])
        let stackPart = line.replacingOccurrences(of: #"^\s*Tech:\s*"#, with: "", options: .regularExpression)
        let stack = stackPart.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let cleaned = content.replacingOccurrences(of: #"(?m)^\s*Tech:\s*.+?\n?"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (stack, cleaned)
    }
}
