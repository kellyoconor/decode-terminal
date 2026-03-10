import SwiftUI

struct NarrationEntryView: View {
    let entry: NarrationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.relativeTime)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(isRecent ? Color(red: 0.086, green: 0.639, blue: 0.290) : Color(red: 0.639, green: 0.639, blue: 0.612))
                Spacer()
                StatusPillView(status: entry.status)
            }
            Text(entry.text)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(isRecent ? Color(red: 0.102, green: 0.102, blue: 0.102) : Color(red: 0.290, green: 0.290, blue: 0.271))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var isRecent: Bool {
        -entry.timestamp.timeIntervalSinceNow < 30
    }
}
