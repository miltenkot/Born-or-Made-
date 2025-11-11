import SwiftUI

struct PlaceholderCard: View {
    var height: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
            .frame(height: height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    PlaceholderCard(height: 80)
}
