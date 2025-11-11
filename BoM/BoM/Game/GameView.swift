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
    
    @ViewBuilder
    private func makeLeftCard(row: Int, rowHeight: CGFloat) -> some View {
        if model.leftItems.indices.contains(row), let item = model.leftItems[row] {
            let title = item.question
            let isSelected = model.isLeftSelected(row)
            let isFrozen = model.isLeftFrozen(row)
            let isMismatch = model.isLeftMismatch(row)
            CardView(
                title: title,
                isSelected: isSelected,
                selectionColor: model.selectionColor(isSelected: isSelected, isMismatch: isMismatch),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: isSelected, isMismatch: isMismatch)
            )
            .frame(height: rowHeight)
            .opacity(isFrozen ? 0.6 : 1.0)
            .contentShape(.rect)
            .onTapGesture {
                guard !isFrozen else { return }
                model.toggleLeftSelection(row)
                if model.selectedLeftIndex != nil, model.selectedRightIndex != nil {
                    Task {
                        await model.confirmSelectionIfMatching()
                    }
                }
            }
            .disabled(isFrozen)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text("Left"))
        } else {
            placeholder(rowHeight: rowHeight)
        }
    }
    
    @ViewBuilder
    private func makeRightCard(row: Int, rowHeight: CGFloat) -> some View {
        if model.rightItems.indices.contains(row), let item = model.rightItems[row] {
            let title = item.answer
            let isSelected = model.isRightSelected(row)
            let isFrozen = model.isRightFrozen(row)
            let isMismatch = model.isRightMismatch(row)
            CardView(
                title: title,
                isSelected: isSelected,
                selectionColor: model.selectionColor(isSelected: isSelected, isMismatch: isMismatch),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: isSelected, isMismatch: isMismatch)
            )
            .frame(height: rowHeight)
            .opacity(isFrozen ? 0.6 : 1.0)
            .contentShape(.rect)
            .onTapGesture {
                guard !isFrozen else { return }
                model.toggleRightSelection(row)
                if model.selectedLeftIndex != nil, model.selectedRightIndex != nil {
                    Task {
                        await model.confirmSelectionIfMatching()
                    }
                }
            }
            .disabled(isFrozen)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text("Right"))
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
