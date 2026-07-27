import Foundation

enum Engine: String, CaseIterable, Identifiable {
    case claudeCode = "Claude Code"
    case codex = "Codex"

    var id: String { rawValue }
}

enum SessionStatus: String, CaseIterable, Identifiable {
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
struct ContextUsage {
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

struct SessionRecord: Identifiable {
    let id: String
    let engine: Engine
    var displayName: String
    let projectPath: String
    let status: SessionStatus
    let lastActiveDescription: String
    let resumeCommand: String
    let contextUsage: ContextUsage?
    let recordSizeDescription: String
}

extension SessionRecord {
    static let mockData: [SessionRecord] = [
        SessionRecord(
            id: "5b7e2f1a-8c3d-4a6e-9f10-2d8b6c4a1e77",
            engine: .claudeCode,
            displayName: "示例项目 A 重构",
            projectPath: "~/demo-project-a",
            status: .active,
            lastActiveDescription: "正在进行 · 2 分钟前",
            resumeCommand: "claude --resume 5b7e2f1a-8c3d-4a6e-9f10-2d8b6c4a1e77",
            contextUsage: ContextUsage(usedTokens: 86_400, windowTokens: nil),
            recordSizeDescription: "4.2 MB · 612 轮"
        ),
        SessionRecord(
            id: "01922f60-3aa4-7c31-9e2b-6f4d8a1c0b53",
            engine: .codex,
            displayName: "示例项目 B 调研",
            projectPath: "~/demo-project-b",
            status: .active,
            lastActiveDescription: "正在进行 · 刚刚",
            resumeCommand: "codex resume 01922f60-3aa4-7c31-9e2b-6f4d8a1c0b53",
            contextUsage: ContextUsage(usedTokens: 41_200, windowTokens: 128_000),
            recordSizeDescription: "1.8 MB · 214 轮"
        ),
        SessionRecord(
            id: "a13e0091-6d2f-4e8a-b451-3c9a7d0e2f64",
            engine: .claudeCode,
            displayName: "示例项目 C 发布",
            projectPath: "~/demo-project-c",
            status: .idle,
            lastActiveDescription: "3 小时前",
            resumeCommand: "claude --resume a13e0091-6d2f-4e8a-b451-3c9a7d0e2f64",
            contextUsage: nil,
            recordSizeDescription: "2.1 MB"
        ),
        SessionRecord(
            id: "01922f61-7b8c-7d42-8a3e-1f5c9b6a4d20",
            engine: .codex,
            displayName: "示例项目 D 改造",
            projectPath: "~/demo-project-d",
            status: .idle,
            lastActiveDescription: "昨天",
            resumeCommand: "codex resume 01922f61-7b8c-7d42-8a3e-1f5c9b6a4d20",
            contextUsage: nil,
            recordSizeDescription: "3.4 MB"
        ),
        SessionRecord(
            id: "01922f62-9d1e-7a53-9b4f-2e6d8c1a5f31",
            engine: .codex,
            displayName: "示例项目 E 审计",
            projectPath: "~/demo-project-e",
            status: .idle,
            lastActiveDescription: "3 天前",
            resumeCommand: "codex resume 01922f62-9d1e-7a53-9b4f-2e6d8c1a5f31",
            contextUsage: nil,
            recordSizeDescription: "6.7 MB"
        ),
        SessionRecord(
            id: "b4c8f221-2e5a-4f8d-9c31-7a0b6d4e8f52",
            engine: .claudeCode,
            displayName: "未命名 session",
            projectPath: "~/demo-project-f",
            status: .expired,
            lastActiveDescription: "28 天前 · 上下文占用高",
            resumeCommand: "claude --resume b4c8f221-2e5a-4f8d-9c31-7a0b6d4e8f52",
            contextUsage: nil,
            recordSizeDescription: "17.3 MB"
        ),
    ]
}
