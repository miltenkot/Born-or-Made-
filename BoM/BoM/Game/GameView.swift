//
//  GameView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI

struct GameView: View {
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let rowsCount: Int = 5
    private let spacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 16
    
    private let items = Array(0..<10)
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - (verticalPadding * 2)
            let rowHeight = max(
                (availableHeight - (CGFloat(rowsCount - 1) * spacing)) / CGFloat(rowsCount),
                0
            )
            
            LazyVGrid(columns: columns, alignment: .center, spacing: spacing) {
                ForEach(items, id: \.self) { index in
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(12)
                        .frame(height: rowHeight)
                        .overlay(
                            Text("Item \(index + 1)")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        )
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(.systemBackground))
    }
}

#Preview {
    GameView()
}
