import Foundation

struct AvailableUpdate: Equatable {
    let version: String
    let dmgURL: URL
}

/// Checks GitHub's latest release against the running build. This is
/// Fleet's only outbound network call — a public, unauthenticated read of
/// the release metadata, never anything from `~/.claude` or `~/.codex`.
enum UpdateChecker {
    private static let repo = "wangduo404-eng/fleet"

    /// Network failures and unparseable responses are treated as "no
    /// update" rather than surfaced as errors — this is a background
    /// convenience check, not something that should ever block or alarm
    /// the user.
    static func checkForUpdate() async -> AvailableUpdate? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String,
              let assets = json["assets"] as? [[String: Any]] else { return nil }

        let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        guard isNewer(latestVersion, than: currentVersion) else { return nil }

        guard let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
              let downloadURLString = dmgAsset["browser_download_url"] as? String,
              let dmgURL = URL(string: downloadURLString) else { return nil }

        return AvailableUpdate(version: latestVersion, dmgURL: dmgURL)
    }

    /// Dot-separated numeric comparison — good enough for Fleet's own
    /// "MAJOR.MINOR.PATCH" tags, not a general semver parser.
    private static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
