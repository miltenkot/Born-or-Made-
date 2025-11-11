//
//  GameView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI

struct GameView: View {
    @State private var model = GameViewModel()
    
    private var maxVisibleRows: Int {
        model.maxVisibleRows
    }
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - (model.verticalPadding * 2)
            let rowHeight = max(
                (availableHeight - (CGFloat(maxVisibleRows - 1) * model.spacing)) / CGFloat(max(maxVisibleRows, 1)),
                0
            )
            
            Grid(horizontalSpacing: model.spacing, verticalSpacing: model.spacing) {
                ForEach(0..<maxVisibleRows, id: \.self) { row in
                    GridRow {
                        makeLeftCard(row: row, rowHeight: rowHeight)
                        makeRightCard(row: row, rowHeight: rowHeight)
                    }
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
    
    private func makeLeftCard(row: Int, rowHeight: CGFloat) -> some View {
        makeCard(
            row: row,
            rowHeight: rowHeight,
            items: model.leftItems,
            titleProvider: { $0.question },
            isSelected: model.isLeftSelected,
            isFrozen: model.isLeftFrozen,
            isMismatch: model.isLeftMismatch,
            toggleSelection: model.toggleLeftSelection,
            accessibilityHint: "Left"
        )
    }
    
    private func makeRightCard(row: Int, rowHeight: CGFloat) -> some View {
        makeCard(
            row: row,
            rowHeight: rowHeight,
            items: model.rightItems,
            titleProvider: { $0.answer },
            isSelected: model.isRightSelected,
            isFrozen: model.isRightFrozen,
            isMismatch: model.isRightMismatch,
            toggleSelection: model.toggleRightSelection,
            accessibilityHint: "Right"
        )
    }
    
    
    @ViewBuilder
    private func makeCard<Item>(
        row: Int,
        rowHeight: CGFloat,
        items: [Item?],
        titleProvider: (Item) -> String,
        isSelected: (Int) -> Bool,
        isFrozen: (Int) -> Bool,
        isMismatch: (Int) -> Bool,
        toggleSelection: @escaping (Int) -> Void,
        accessibilityHint: String
    ) -> some View {
        if items.indices.contains(row), let item = items[row] {
            let title = titleProvider(item)
            let selected = isSelected(row)
            let frozen = isFrozen(row)
            let mismatch = isMismatch(row)
            
            CardView(
                title: title,
                isSelected: selected,
                selectionColor: model.selectionColor(isSelected: selected, isMismatch: mismatch),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: selected, isMismatch: mismatch),
                accessibilityHint: accessibilityHint
            )
            .frame(height: rowHeight)
            .opacity(frozen ? 0.6 : 1.0)
            .contentShape(.rect)
            .onTapGesture {
                guard !frozen else { return }
                toggleSelection(row)
                if model.selectedLeftIndex != nil, model.selectedRightIndex != nil {
                    Task {
                        await model.confirmSelectionIfMatching()
                    }
                }
            }
            .disabled(frozen)
        } else {
            placeholder(rowHeight: rowHeight)
        }
    }
    
    // MARK: - Placeholder
    
    @ViewBuilder
    private func placeholder(rowHeight: CGFloat) -> some View {
        Rectangle()
            .fill(Color.blue.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
            .allowsHitTesting(false)
            .frame(height: rowHeight)
            .accessibilityHidden(true)
    }
}

#Preview {
    GameView()
}
