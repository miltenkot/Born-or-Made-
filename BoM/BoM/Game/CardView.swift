//
//  CardView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI

struct CardView: View {
    let title: String
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .cornerRadius(12)
            .overlay(
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.blue)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
    }
}

#Preview {
    CardView(title: "title")
}
