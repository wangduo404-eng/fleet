# Fleet

Mac 端 CLI Session 追踪工具 —— 扫描并展示本机 **Claude Code** / **Codex** 的历史与当前活跃 session，支持备注命名和复制恢复命令。

## 状态

需求已收窄为 v1：获取记录（扫描/展示/活跃状态识别）+ 复制恢复命令，一键打开终端延后到后续迭代。UI 已选定设计稿 V1，静态骨架（写死示例数据）已能跑起来，真实的 session 扫描逻辑尚未接入。

- 需求与技术调研：[session-tracker-需求文档.md](./session-tracker-需求文档.md)
- UI 设计稿：[V1](./Fleet-设计稿V1.md)（当前采用）· [V2](./Fleet-设计稿V2.md) · [V3](./Fleet-设计稿V3.md)

## 技术方向

原生 SwiftUI，独立菜单栏 App（`LSUIElement`，无 Dock 图标），不常驻后台，按需冷启动扫描。

## 开发

用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成工程（`Fleet.xcodeproj` 不进库，由 `project.yml` 生成）：

```
xcodegen generate
open Fleet.xcodeproj
```

或直接命令行构建：

```
xcodegen generate
xcodebuild -project Fleet.xcodeproj -scheme Fleet -configuration Debug build
```

## License

[MIT](./LICENSE)
