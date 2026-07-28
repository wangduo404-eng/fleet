import SwiftUI

/// Inline-editable session name: shows a pencil affordance that swaps the
/// label for a text field. Used by both the active-session card and the
/// compact list row so rename works the same way everywhere.
struct EditableNameLabel: View {
    let name: String
    let font: Font
    let textColor: Color
    let onRename: (String) -> Void

    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isEditing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(font)
                    .focused($isFocused)
                    .onSubmit(commit)
                    .onExitCommand { isEditing = false }
            } else {
                Text(name)
                    .font(font)
                    .foregroundStyle(textColor)
            }

            Button {
                if isEditing {
                    commit()
                } else {
                    draft = name
                    isEditing = true
                    isFocused = true
                }
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(textColor.opacity(0.85))
        }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onRename(trimmed)
        }
        isEditing = false
    }
}
