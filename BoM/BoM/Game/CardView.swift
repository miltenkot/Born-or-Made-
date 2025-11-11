//
//  CardView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI

struct CardView: View {
    let title: String
    var isSelected: Bool = false
    var selectionColor: Color = .blue
    var selectionBackgroundColor: Color = Color.blue.opacity(0.2)
    var accessibilityHint: String = ""
    
    var body: some View {
        Rectangle()
            .fill(selectionBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? selectionColor : Color.blue, lineWidth: isSelected ? 4 : 2)
            )
            .cornerRadius(12)
            .overlay(
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.blue)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text(accessibilityHint))
    }
}

#Preview {
    VStack(spacing: 16) {
        CardView(title: "Not selected")
            .frame(height: 80)
        CardView(title: "Selected non-matching", isSelected: true, selectionBackgroundColor: Color.blue.opacity(0.15))
            .frame(height: 80)
        CardView(title: "Selected matching", isSelected: true, selectionColor: .green, selectionBackgroundColor: Color.green.opacity(0.25))
            .frame(height: 80)
    }
    .padding()
}

