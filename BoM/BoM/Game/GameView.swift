//
//  GameView.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI
import Observation

struct GameView: View {
    @State private var model = GameViewModel()
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    init() { }
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - (model.verticalPadding * 2)
            let rowHeight = max(
                (availableHeight - (CGFloat(model.rowsCount - 1) * model.spacing)) / CGFloat(max(model.rowsCount, 1)),
                0
            )
            
            LazyVGrid(columns: columns, alignment: .center, spacing: model.spacing) {
                ForEach(0..<model.rowsCount, id: \.self) { row in
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Shuffle") {
                    model.shuffleRight()
                }
            }
        }
    }
    
    // MARK: - Card builders
    
    @ViewBuilder
    private func makeLeftCard(row: Int, rowHeight: CGFloat) -> some View {
        let title = model.roundItems.indices.contains(row) ? model.roundItems[row].question : ""
        let isSelected = model.isLeftSelected(row)
        CardView(
            title: title,
            isSelected: isSelected,
            selectionColor: model.selectionColor(isSelected: isSelected)
        )
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture { model.toggleLeftSelection(row) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text("Left"))
    }
    
    @ViewBuilder
    private func makeRightCard(row: Int, rowHeight: CGFloat) -> some View {
        let title = model.rightItems.indices.contains(row) ? model.rightItems[row].answer : ""
        let isSelected = model.isRightSelected(row)
        CardView(
            title: title,
            isSelected: isSelected,
            selectionColor: model.selectionColor(isSelected: isSelected)
        )
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture { model.toggleRightSelection(row) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text("Right"))
    }
}

#Preview {
    GameView()
}
