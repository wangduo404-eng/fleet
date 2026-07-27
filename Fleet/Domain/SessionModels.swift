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

struct SessionRecord: Identifiable {
    let id: String
    let engine: Engine
    let displayName: String
    let projectPath: String
    let status: SessionStatus
    let lastActiveDescription: String
    let resumeCommand: String
}

extension SessionRecord {
    static let mockData: [SessionRecord] = [
        SessionRecord(
            id: "9f2a1c7e-...",
            engine: .claudeCode,
            displayName: "示例项目 A 重构",
            projectPath: "~/demo-project-a",
            status: .active,
            lastActiveDescription: "正在进行 · 2 分钟前",
            resumeCommand: "claude --resume 9f2a1c7e-..."
        ),
        SessionRecord(
            id: "019fa225-...",
            engine: .codex,
            displayName: "示例项目 B 调研",
            projectPath: "~/demo-project-b",
            status: .active,
            lastActiveDescription: "正在进行 · 刚刚",
            resumeCommand: "codex resume 019fa225-..."
        ),
        SessionRecord(
            id: "a13e0091-...",
            engine: .claudeCode,
            displayName: "示例项目 C 发布",
            projectPath: "~/demo-project-c",
            status: .idle,
            lastActiveDescription: "3 小时前",
            resumeCommand: "claude --resume a13e0091-..."
        ),
        SessionRecord(
            id: "019f9ef4-...",
            engine: .codex,
            displayName: "示例项目 D 改造",
            projectPath: "~/demo-project-d",
            status: .idle,
            lastActiveDescription: "昨天",
            resumeCommand: "codex resume 019f9ef4-..."
        ),
        SessionRecord(
            id: "019f7a33-...",
            engine: .codex,
            displayName: "示例项目 E 审计",
            projectPath: "~/demo-project-e",
            status: .idle,
            lastActiveDescription: "3 天前",
            resumeCommand: "codex resume 019f7a33-..."
        ),
        SessionRecord(
            id: "b4c8f221-...",
            engine: .claudeCode,
            displayName: "未命名 session",
            projectPath: "~/demo-project-f",
            status: .expired,
            lastActiveDescription: "28 天前 · 上下文占用高",
            resumeCommand: "claude --resume b4c8f221-..."
        ),
    ]
}
