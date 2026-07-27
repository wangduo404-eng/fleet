import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.top, 20)
                .padding(.horizontal, 18)

            Text("你的终端船队")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 18)
                .padding(.top, 2)
                .padding(.bottom, 20)

            filterSection(title: "状态") {
                ForEach(StatusFilter.allCases) { status in
                    filterRow(
                        label: status.rawValue,
                        count: model.count(for: status),
                        isSelected: model.statusFilter == status,
                        dotColor: dotColor(for: status)
                    ) {
                        model.statusFilter = status
                    }
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)

            filterSection(title: "引擎") {
                filterRow(
                    label: "全部引擎",
                    count: model.sessions.count,
                    isSelected: model.engineFilter == nil,
                    dotColor: nil
                ) {
                    model.engineFilter = nil
                }
                ForEach(Engine.allCases) { engine in
                    filterRow(
                        label: engine.rawValue,
                        count: model.count(for: engine),
                        isSelected: model.engineFilter == engine,
                        dotColor: nil
                    ) {
                        model.engineFilter = engine
                    }
                }
            }

            Spacer()

            Label("设置", systemImage: "gearshape")
                .font(.system(size: 12.5))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
        }
        .frame(width: 216, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(FleetColor.sidebarBackground)
    }

    private var brand: some View {
        HStack(spacing: 8) {
            Image(systemName: "sailboat.fill")
                .font(.system(size: 15))
                .foregroundStyle(FleetColor.mint)
            Text("Fleet")
                .font(FleetFont.brandTitle(19))
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10.5))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 18)
                .padding(.bottom, 4)
            content()
        }
    }

    private func filterRow(
        label: String,
        count: Int,
        isSelected: Bool,
        dotColor: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.75))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(isSelected ? FleetColor.sidebarAccent.opacity(0.5) : .clear)
        }
        .buttonStyle(.plain)
    }

    private func dotColor(for status: StatusFilter) -> Color? {
        switch status {
        case .all: return nil
        case .active: return FleetColor.mint
        case .idle: return .white.opacity(0.4)
        case .expired: return FleetColor.expired
        }
    }
}
