import Foundation

enum Engine: String, CaseIterable, Identifiable, Sendable {
    case claudeCode = "Claude Code"
    case codex = "Codex"

    var id: String { rawValue }
}

enum SessionStatus: String, CaseIterable, Identifiable, Sendable {
    case active = "活跃"
    case idle = "空闲"
    case expired = "疑似过期"

    var id: String { rawValue }
}

/// Context-window usage for an active session.
///
/// Claude Code's session files don't record the model's context window limit,
/// so only an approximate token count can be shown. Codex's `token_count`
/// events include `model_context_window`, so an exact percentage is possible.
/// See session-tracker-需求文档.md 4.1 for the underlying research.
struct ContextUsage: Sendable {
    let usedTokens: Int
    let windowTokens: Int?

    var description: String {
        let used = Self.format(usedTokens)
        guard let windowTokens else {
            return "≈\(used) tokens（无法确定窗口上限）"
        }
        let percent = Int((Double(usedTokens) / Double(windowTokens) * 100).rounded())
        return "\(used) / \(Self.format(windowTokens)) tokens · \(percent)%"
    }

    var fraction: Double? {
        guard let windowTokens, windowTokens > 0 else { return nil }
        return min(1, Double(usedTokens) / Double(windowTokens))
    }

    private static func format(_ value: Int) -> String {
        value >= 1000 ? String(format: "%.1fK", Double(value) / 1000) : "\(value)"
    }
}

struct SessionRecord: Identifiable, Sendable {
    /// How long since last activity before an idle session counts as
    /// "疑似过期" — a heuristic, easy to retune later.
    static let expiredThreshold: TimeInterval = 14 * 24 * 3600

    /// Separate from `expiredThreshold` — this is purely a UI decluttering
    /// threshold. With 245+ historical sessions, anything untouched for a
    /// month gets folded away behind a "show older" disclosure by default.
    static let longUnusedThreshold: TimeInterval = 30 * 24 * 3600

    let id: String
    let engine: Engine
    var displayName: String
    let projectPath: String
    let isActive: Bool
    let lastActiveAt: Date
    let fileSizeBytes: Int64
    let contextUsage: ContextUsage?
    let resumeCommand: String

    var status: SessionStatus {
        if isActive { return .active }
        return Date().timeIntervalSince(lastActiveAt) > Self.expiredThreshold ? .expired : .idle
    }

    var lastActiveDescription: String {
        chineseRelativeTime(from: lastActiveAt, isActive: isActive)
    }

    var recordSizeDescription: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    var isLongUnused: Bool {
        !isActive && Date().timeIntervalSince(lastActiveAt) > Self.longUnusedThreshold
    }
}

func chineseRelativeTime(from date: Date, isActive: Bool) -> String {
    let seconds = max(0, Int(Date().timeIntervalSince(date)))
    let minutes = seconds / 60
    let hours = minutes / 60
    let days = hours / 24

    let suffix: String
    if seconds < 60 { suffix = "刚刚" }
    else if minutes < 60 { suffix = "\(minutes) 分钟前" }
    else if hours < 24 { suffix = "\(hours) 小时前" }
    else if days == 1 { suffix = "昨天" }
    else { suffix = "\(days) 天前" }

    return isActive ? "正在进行 · \(suffix)" : suffix
}
