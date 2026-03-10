import SwiftUI

struct NarrationEntryView: View {
    let entry: NarrationEntry

    var body: some View {
        if entry.status == .waitingForInput {
            waitingCard
        } else {
            standardEntry
        }
    }

    private var standardEntry: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.timeLabel)
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(Color(red: 0.639, green: 0.639, blue: 0.612))
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

    /// Distinct card for when the agent needs user input
    private var waitingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.965))
                Text("Needs your input")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.965))
                Spacer()
                Text(entry.timeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.639, green: 0.639, blue: 0.612))
            }
            Text(entry.text)
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.2), lineWidth: 1)
        )
    }

    private var isRecent: Bool {
        -entry.timestamp.timeIntervalSinceNow < 30
    }
}
