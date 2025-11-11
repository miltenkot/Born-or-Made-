//
//  GameViewModel.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class GameViewModel {
    // Layout configuration
    let spacing: CGFloat = 12
    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 16
    let maxVisibleRows: Int = 5
    // Fixed number of rows in the grid (5 rows x 2 columns = 10 slots)
    let fixedRows: Int = 5
    
    // Source data (eventually may come from a service)
    let qaItems: [QAItem] = [
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
    
    // Game state
    var roundItems: [QAItem] = []
    var rightItems: [QAItem] = []
    
    var selectedLeftIndex: Int? = nil
    var selectedRightIndex: Int? = nil
    
    // Computed properties
    var rowsCount: Int { min(qaItems.count, maxVisibleRows) }
    
    var isCurrentSelectionMatching: Bool {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            roundItems.indices.contains(li),
            rightItems.indices.contains(ri)
        else { return false }
        return roundItems[li].answer == rightItems[ri].answer
    }
    
    // API
    func setupRound() {
        roundItems = Array(qaItems.shuffled().prefix(rowsCount))
        rightItems = roundItems.shuffled()
        selectedLeftIndex = nil
        selectedRightIndex = nil
    }
    
    func isLeftSelected(_ row: Int) -> Bool {
        selectedLeftIndex == row
    }
    
    func isRightSelected(_ row: Int) -> Bool {
        selectedRightIndex == row
    }
    
    func selectionColor(isSelected: Bool) -> Color {
        (isSelected && isCurrentSelectionMatching) ? .green : .blue
    }
    
    func toggleLeftSelection(_ row: Int) {
        selectedLeftIndex = (selectedLeftIndex == row) ? nil : row
    }
    
    func toggleRightSelection(_ row: Int) {
        selectedRightIndex = (selectedRightIndex == row) ? nil : row
    }
}
