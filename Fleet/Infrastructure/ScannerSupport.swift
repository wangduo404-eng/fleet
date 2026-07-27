import Foundation

enum ScannerSupport {
    static func shortenedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    /// Used when neither Fleet's own name store nor the engine has anything
    /// better (e.g. Codex's `thread_name`) to show.
    static func fallbackName(projectPath: String, id: String) -> String {
        let projectName = URL(fileURLWithPath: projectPath).lastPathComponent
        let shortID = String(id.prefix(8))
        return projectName.isEmpty ? shortID : "\(projectName) · \(shortID)"
    }
}
