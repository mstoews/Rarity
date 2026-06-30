import SwiftUI

/// Read-only star display (fractional support).
struct StarRatingView: View {
    let rating: Double
    let max: Int
    var size: CGFloat = 14

    init(rating: Double, max: Int = 5, size: CGFloat = 14) {
        self.rating = rating; self.max = max; self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...max, id: \.self) { i in
                Image(systemName: starName(for: i))
                    .font(.system(size: size))
                    .foregroundStyle(rating >= Double(i) - 0.25 ? Theme.star : Theme.hint)
            }
        }
    }

    private func starName(for i: Int) -> String {
        let d = rating - Double(i - 1)
        if d >= 0.75 { return "star.fill" }
        if d >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Interactive star picker.
struct StarPickerView: View {
    @Binding var rating: Int
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i <= rating ? Theme.star : Theme.hint)
                    .onTapGesture { rating = i }
            }
        }
    }
}
