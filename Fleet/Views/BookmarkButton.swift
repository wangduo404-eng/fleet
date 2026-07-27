import SwiftUI

struct BookmarkButton: View {
    let session: SessionRecord
    var size: CGFloat = 11
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Button {
            model.toggleBookmark(session)
        } label: {
            Image(systemName: session.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: size))
        }
        .buttonStyle(.plain)
        .help(session.isBookmarked ? "取消书签" : "加入书签")
    }
}
