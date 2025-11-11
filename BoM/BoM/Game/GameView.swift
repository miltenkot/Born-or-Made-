//
//  GameView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI

struct GameView: View {
    @State private var model = GameViewModel()
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var fixedRows: Int {
        model.fixedRows
    }
    
    init() { }
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - (model.verticalPadding * 2)
            let rowHeight = max(
                (availableHeight - (CGFloat(fixedRows - 1) * model.spacing)) / CGFloat(max(fixedRows, 1)),
                0
            )
            
            LazyVGrid(columns: columns, alignment: .center, spacing: model.spacing) {
                ForEach(0..<fixedRows, id: \.self) { row in
                    makeLeftCard(row: row, rowHeight: rowHeight)
                    makeRightCard(row: row, rowHeight: rowHeight)
                }
            }
            .padding(.horizontal, model.horizontalPadding)
            .padding(.vertical, model.verticalPadding)
        }
        .onAppear {
            model.setupRound()
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Card builders
    
    @ViewBuilder
    private func makeLeftCard(row: Int, rowHeight: CGFloat) -> some View {
        if model.roundItems.indices.contains(row), let item = model.roundItems[row] {
            let title = item.question
            let isSelected = model.isLeftSelected(row)
            CardView(
                title: title,
                isSelected: isSelected,
                selectionColor: model.selectionColor(isSelected: isSelected),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: isSelected)
            )
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                model.toggleLeftSelection(row)
                // If both sides are selected, attempt to confirm and refill
                if model.selectedLeftIndex != nil, model.selectedRightIndex != nil {
                    model.confirmSelectionIfMatching()
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text("Left"))
        } else {
            placeholderCard()
                .frame(height: rowHeight)
                .accessibilityHidden(true)
        }
    }
    
    @ViewBuilder
    private func makeRightCard(row: Int, rowHeight: CGFloat) -> some View {
        if model.rightItems.indices.contains(row), let item = model.rightItems[row] {
            let title = item.answer
            let isSelected = model.isRightSelected(row)
            CardView(
                title: title,
                isSelected: isSelected,
                selectionColor: model.selectionColor(isSelected: isSelected),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: isSelected)
            )
            .frame(height: rowHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                model.toggleRightSelection(row)
                // If both sides are selected, attempt to confirm and refill
                if model.selectedLeftIndex != nil, model.selectedRightIndex != nil {
                    model.confirmSelectionIfMatching()
                }
            }
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text("Right"))
        } else {
            placeholderCard()
                .frame(height: rowHeight)
                .accessibilityHidden(true)
        }
    }
    
    // MARK: - Placeholder
    
    private func placeholderCard() -> some View {
        // Looks like a card but empty and non-interactive
        Rectangle()
            .fill(Color.blue.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
            .overlay(
                Text("") // no title
            )
            .allowsHitTesting(false)
    }
}

#Preview {
    GameView()
}

