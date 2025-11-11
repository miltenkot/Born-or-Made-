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
            isMatch: model.isLeftMatch,
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
            isMatch: model.isRightMatch,
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
        isMatch: (Int) -> Bool,
        toggleSelection: @escaping (Int) -> Void,
        accessibilityHint: String
    ) -> some View {
        if items.indices.contains(row), let item = items[row] {
            let title = titleProvider(item)
            let selected = isSelected(row)
            let frozen = isFrozen(row)
            let mismatch = isMismatch(row)
            let match = isMatch(row)
            
            CardView(
                title: title,
                isSelected: selected,
                selectionColor: model.selectionColor(isSelected: selected, isMismatch: mismatch, isMatch: match),
                selectionBackgroundColor: model.selectionBackgroundColor(isSelected: selected, isMismatch: mismatch, isMatch: match),
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
            PlaceholderCard(height: rowHeight)
        }
    }
}

#Preview {
    GameView()
}
