import SwiftUI

struct StatusIndicatorView: View {
    let state: ModelState
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)

            if showLabel {
                Text(state.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
