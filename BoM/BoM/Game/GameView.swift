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
    private let spacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 16
    private let maxVisibleRows: Int = 5
    
    private let qaItems: [QAItem] = [
        QAItem(question: "Stolica Francji", answer: "Paryż"),
        QAItem(question: "2 + 2", answer: "4"),
        QAItem(question: "Kolor nieba", answer: "Niebieski"),
        QAItem(question: "Język projektu", answer: "Swift"),
        QAItem(question: "Rok przestępny", answer: "366 dni"),
        QAItem(question: "Stolica Niemiec", answer: "Berlin"),
        QAItem(question: "3 * 3", answer: "9"),
        QAItem(question: "Stolica Włoch", answer: "Rzym"),
        QAItem(question: "Autor 'Pan Tadeusz'", answer: "Adam Mickiewicz"),
        QAItem(question: "Pierwiastek z 16", answer: "4"),
        QAItem(question: "Kolor trawy", answer: "Zielony"),
        QAItem(question: "Język na iOS", answer: "Swift"),
        QAItem(question: "Stolica Hiszpanii", answer: "Madryt"),
        QAItem(question: "5 - 2", answer: "3"),
        QAItem(question: "Stolica Polski", answer: "Warszawa"),
        QAItem(question: "7 + 5", answer: "12"),
        QAItem(question: "Kolor krwi", answer: "Czerwony"),
        QAItem(question: "Miesiące w roku", answer: "12"),
        QAItem(question: "Doba ma", answer: "24 godziny"),
        QAItem(question: "Stolica Portugalii", answer: "Lizbona")
    ]
    
    private var rowsCount: Int { min(qaItems.count, maxVisibleRows) }
    
    @State private var roundItems: [QAItem] = []
    @State private var rightItems: [QAItem] = []
    
    @State private var selectedLeftIndex: Int? = nil
    @State private var selectedRightIndex: Int? = nil
    
    private var isCurrentSelectionMatching: Bool {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            roundItems.indices.contains(li),
            rightItems.indices.contains(ri)
        else { return false }
        return roundItems[li].answer == rightItems[ri].answer
    }
    
    init() {
        
    }
    
    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - (verticalPadding * 2)
            let rowHeight = max(
                (availableHeight - (CGFloat(rowsCount - 1) * spacing)) / CGFloat(max(rowsCount, 1)),
                0
            )
            
            LazyVGrid(columns: columns, alignment: .center, spacing: spacing) {
                ForEach(0..<rowsCount, id: \.self) { row in
                    makeLeftCard(row: row, rowHeight: rowHeight)
                    makeRightCard(row: row, rowHeight: rowHeight)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .onAppear {
            setupRound()
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Shuffle") {
                    shuffleRight()
                }
            }
        }
    }
    
    // MARK: - Card builders
    
    @ViewBuilder
    private func makeLeftCard(row: Int, rowHeight: CGFloat) -> some View {
        let title = roundItems.indices.contains(row) ? roundItems[row].question : ""
        let isSelected = isLeftSelected(row)
        CardView(
            title: title,
            isSelected: isSelected,
            selectionColor: selectionColor(isSelected: isSelected)
        )
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture { toggleLeftSelection(row) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text("Left"))
    }
    
    @ViewBuilder
    private func makeRightCard(row: Int, rowHeight: CGFloat) -> some View {
        let title = rightItems.indices.contains(row) ? rightItems[row].answer : ""
        let isSelected = isRightSelected(row)
        CardView(
            title: title,
            isSelected: isSelected,
            selectionColor: selectionColor(isSelected: isSelected)
        )
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        .onTapGesture { toggleRightSelection(row) }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text("Right"))
    }
    
    // MARK: - Selection helpers
    
    private func isLeftSelected(_ row: Int) -> Bool {
        selectedLeftIndex == row
    }
    
    private func isRightSelected(_ row: Int) -> Bool {
        selectedRightIndex == row
    }
    
    private func selectionColor(isSelected: Bool) -> Color {
        (isSelected && isCurrentSelectionMatching) ? .green : .blue
    }
    
    private func toggleLeftSelection(_ row: Int) {
        selectedLeftIndex = (selectedLeftIndex == row) ? nil : row
    }
    
    private func toggleRightSelection(_ row: Int) {
        selectedRightIndex = (selectedRightIndex == row) ? nil : row
    }
    
    // MARK: - Round setup/shuffle
    
    private func setupRound() {
        roundItems = Array(qaItems.shuffled().prefix(rowsCount))
        rightItems = roundItems.shuffled()
        selectedLeftIndex = nil
        selectedRightIndex = nil
    }
    
    private func shuffleRight() {
        rightItems = roundItems.shuffled()
        selectedRightIndex = nil
    }
}

#Preview {
    GameView()
}
