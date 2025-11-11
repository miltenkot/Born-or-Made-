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
//        QAItem(question: "Autor 'Pan Tadeusz'", answer: "Adam Mickiewicz"),
//        QAItem(question: "Pierwiastek z 16", answer: "4"),
//        QAItem(question: "Kolor trawy", answer: "Zielony"),
//        QAItem(question: "Język na iOS", answer: "Swift"),
//        QAItem(question: "Stolica Hiszpanii", answer: "Madryt"),
//        QAItem(question: "5 - 2", answer: "3"),
//        QAItem(question: "Stolica Polski", answer: "Warszawa"),
//        QAItem(question: "7 + 5", answer: "12"),
//        QAItem(question: "Kolor krwi", answer: "Czerwony"),
//        QAItem(question: "Miesiące w roku", answer: "12"),
//        QAItem(question: "Doba ma", answer: "24 godziny"),
//        QAItem(question: "Stolica Portugalii", answer: "Lizbona")
    ]
    
    // Game state
    var roundItems: [QAItem] = []
    var rightItems: [QAItem] = []
    
    // Pool of remaining, not yet used items
    private var remainingItems: [QAItem] = []
    
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
        return roundItems[li].id == rightItems[ri].id
    }
    
    // API
    func setupRound() {
        // Start a new pool
        remainingItems = qaItems.shuffled()
        // Fill initial round
        roundItems = Array(remainingItems.prefix(rowsCount))
        remainingItems.removeFirst(roundItems.count)
        // Right column is a shuffled permutation of current round items
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
    
    // Call after both sides are selected to handle match and refill
    func confirmSelectionIfMatching() {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            roundItems.indices.contains(li),
            rightItems.indices.contains(ri)
        else { return }
        
        let leftItem = roundItems[li]
        let rightItem = rightItems[ri]
        
        // Check by identity to avoid ambiguity on duplicate answers
        guard leftItem.id == rightItem.id else {
            // Not a match, just keep selection logic as you like
            return
        }
        
        // Remove matched items from both arrays.
        // We remove by ID to be robust if indices shift.
        roundItems.removeAll { $0.id == leftItem.id }
        rightItems.removeAll { $0.id == rightItem.id }
        
        // Refill to keep fixedRows if possible
        while roundItems.count < rowsCount, !remainingItems.isEmpty {
            roundItems.append(remainingItems.removeFirst())
        }
        
        // Right column must remain a permutation of left column
        rightItems = roundItems.shuffled()
        
        // Clear selection after processing
        selectedLeftIndex = nil
        selectedRightIndex = nil
    }
}

