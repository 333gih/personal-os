import Foundation

enum POSFormatting {
    static func relativeDate(_ iso: String) -> String {
        let parsers: [String] = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        var date: Date?
        for pattern in parsers {
            formatter.dateFormat = pattern
            if let parsed = formatter.date(from: iso) {
                date = parsed
                break
            }
        }
        guard let date else { return iso }

        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }

    static func friendlyDue(_ iso: String) -> String {
        let parsers: [String] = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for pattern in parsers {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: iso) {
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
        }
        return iso
    }

    static func humanType(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func domainLabel(_ domain: String) -> String {
        switch domain {
        case "work": return "Work"
        case "learning": return "Learning"
        case "startup": return "Startup"
        case "inbox": return "Inbox"
        case "entertainment": return "Reading"
        default: return domain.capitalized
        }
    }

    static func monthYear(_ iso: String) -> String {
        let prefix = String(iso.prefix(10))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: prefix) else { return iso }
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

enum POSLoadTask {
    /// SwiftUI `.task(id: accessToken)` and URLSession cancel in-flight loads when the token refreshes.
    static func isBenignCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let url = error as? URLError, url.code == .cancelled { return true }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled
    }
}
