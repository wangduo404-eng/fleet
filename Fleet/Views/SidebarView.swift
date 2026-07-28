import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.top, 26)
                .padding(.horizontal, 24)

            Text("你的终端船队")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 24)
                .padding(.top, 3)
                .padding(.bottom, 24)

            VStack(spacing: 3) {
                primaryNavItem(icon: "house.fill", label: "首页", count: model.homeClaudeSessions.count + model.homeCodexSessions.count, mode: .home)
                primaryNavItem(icon: "bookmark.fill", label: "书签", count: model.bookmarkedSessions.count, mode: .bookmarks)
            }
            .padding(.horizontal, 13)
            .padding(.bottom, 21)

            Text("浏览全部 SESSION")
                .font(.system(size: 13))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.32))
                .padding(.horizontal, 24)
                .padding(.bottom, 11)

            filterSection(title: "引擎") {
                filterRow(
                    label: "全部引擎",
                    count: model.sessions.count,
                    isSelected: browsing && model.engineFilter == nil,
                    dotColor: nil
                ) {
                    model.viewMode = .browse
                    model.engineFilter = nil
                }
                ForEach(Engine.allCases) { engine in
                    filterRow(
                        label: engine.rawValue,
                        count: model.count(for: engine),
                        isSelected: browsing && model.engineFilter == engine,
                        swatchColor: engine.accentColor
                    ) {
                        model.viewMode = .browse
                        model.engineFilter = engine
                    }
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            filterSection(title: "来源") {
                filterRow(
                    label: "全部来源",
                    count: model.sessions.count,
                    isSelected: browsing && model.originFilter == nil
                ) {
                    model.viewMode = .browse
                    model.originFilter = nil
                }
                ForEach(SessionOrigin.allCases) { origin in
                    filterRow(
                        label: origin.rawValue,
                        count: model.count(for: origin),
                        isSelected: browsing && model.originFilter == origin
                    ) {
                        model.viewMode = .browse
                        model.originFilter = origin
                    }
                }
            }

            Spacer()

            Label("设置", systemImage: "gearshape")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(width: 282, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(FleetColor.sidebarBackground)
    }

    private var browsing: Bool { model.viewMode == .browse }

    private func primaryNavItem(icon: String, label: String, count: Int, mode: ViewMode) -> some View {
        let isOn = model.viewMode == mode
        return Button {
            model.viewMode = mode
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 15, weight: .semibold))
                    .opacity(0.75)
            }
            .padding(11)
            .foregroundStyle(isOn ? FleetColor.sidebarBackground : .white.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isOn ? FleetColor.mint : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var brand: some View {
        HStack(spacing: 11) {
            Image(systemName: "sailboat.fill")
                .font(.system(size: 20))
                .foregroundStyle(FleetColor.mint)
            Text("Fleet")
                .font(FleetFont.brandTitle(25))
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 14))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 24)
                .padding(.bottom, 5)
            content()
        }
    }

    private func filterRow(
        label: String,
        count: Int,
        isSelected: Bool,
        dotColor: Color? = nil,
        swatchColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                }
                if let swatchColor {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(swatchColor)
                        .frame(width: 13, height: 13)
                }
                Text(label)
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.75))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 15.5))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 9)
            .background(isSelected ? FleetColor.sidebarAccent.opacity(0.5) : .clear)
        }
        .buttonStyle(.plain)
    }

}
