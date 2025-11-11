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
        QAItem(question: "Język używany do tworzenia aplikacji na iOS", answer: "Swift"),
        QAItem(question: "Rok przestępny ma", answer: "366 dni"),
        QAItem(question: "Stolica Niemiec", answer: "Berlin"),
        QAItem(question: "3 * 3", answer: "9"),
        QAItem(question: "Stolica Włoch", answer: "Rzym"),
        QAItem(question: "Autor 'Pana Tadeusza'", answer: "Adam Mickiewicz"),
        QAItem(question: "Pierwiastek kwadratowy z 16", answer: "4"),
        QAItem(question: "Kolor trawy", answer: "Zielony"),
        QAItem(question: "System operacyjny Apple dla telefonów", answer: "iOS"),
        QAItem(question: "Stolica Hiszpanii", answer: "Madryt"),
        QAItem(question: "5 - 2", answer: "3"),
        QAItem(question: "Stolica Polski", answer: "Warszawa"),
        QAItem(question: "7 + 5", answer: "12"),
        QAItem(question: "Kolor krwi", answer: "Czerwony"),
        QAItem(question: "Liczba miesięcy w roku", answer: "12"),
        QAItem(question: "Doba ma", answer: "24 godziny"),
        QAItem(question: "Stolica Portugalii", answer: "Lizbona")
    ]

    
    // Game state
    var roundItems: [QAItem?] = []
    var rightItems: [QAItem?] = []
    
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
            rightItems.indices.contains(ri),
            let l = roundItems[li],
            let r = rightItems[ri]
        else { return false }
        return l.id == r.id
    }
    
    // API
    func setupRound() {
        // Start a new pool
        remainingItems = qaItems.shuffled()
        
        // Prepare columns with fixed size = fixedRows
        roundItems = Array(repeating: nil, count: fixedRows)
        rightItems = Array(repeating: nil, count: fixedRows)
        
        // Fill initial round in first rowsCount slots
        for i in 0..<rowsCount {
            if let next = remainingItems.first {
                roundItems[i] = next
                remainingItems.removeFirst()
            }
        }
        // Build initial right as a permutation of left, but placed into the same occupied slots,
        // so layout is stable from the start.
        rebuildRightPreservingStableSlots()
        
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
    
    // New: background color for selected state
    func selectionBackgroundColor(isSelected: Bool) -> Color {
        guard isSelected else { return Color.blue.opacity(0.2) }
        return isCurrentSelectionMatching
            ? Color.green.opacity(0.25)
            : Color.blue.opacity(0.15)
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
            rightItems.indices.contains(ri),
            let leftItem = roundItems[li],
            let rightItem = rightItems[ri]
        else { return }
        
        // Check by identity to avoid ambiguity on duplicate answers
        guard leftItem.id == rightItem.id else {
            // Not a match, just keep selection logic as you like
            return
        }
        
        // 1) Replace only the left slot with a new item (or nil if pool empty)
        if !remainingItems.isEmpty {
            roundItems[li] = remainingItems.removeFirst()
        } else {
            roundItems[li] = nil
        }
        
        // 2) Rebuild right column as a permutation of current left,
        //    preserving stable positions where possible.
        rebuildRightPreservingStableSlots()
        
        // Clear selection after processing
        selectedLeftIndex = nil
        selectedRightIndex = nil
    }
    
    // MARK: - Right column rebuild preserving stable slots
    private func rebuildRightPreservingStableSlots() {
        // Desired multiset = all non-nil items on the left
        let desired = roundItems.compactMap { $0 }
        var remainingToPlace = desired
        
        // First pass: keep items that are still present and placed on the same index
        // We try to preserve slots where the current right item is still in desired set.
        var newRight: [QAItem?] = Array(repeating: nil, count: fixedRows)
        for i in 0..<fixedRows {
            guard let leftAtI = roundItems[i] else {
                // left is empty -> right must be empty
                continue
            }
            if let currentRight = rightItems.indices.contains(i) ? rightItems[i] : nil,
               let idx = remainingToPlace.firstIndex(of: currentRight),
               // ensure we don't accidentally reveal the pair by keeping right equal to left at same index
               currentRight.id != leftAtI.id {
                newRight[i] = currentRight
                remainingToPlace.remove(at: idx)
            }
        }
        
        // Second pass: fill empty right slots that correspond to non-nil left slots
        // with a random permutation from the remaining pool, avoiding same-index pair.
        remainingToPlace.shuffle()
        for i in 0..<fixedRows {
            guard newRight[i] == nil, let leftAtI = roundItems[i] else { continue }
            // pick an element whose id != leftAtI.id if possible
            if let safeIdx = remainingToPlace.firstIndex(where: { $0.id != leftAtI.id }) {
                newRight[i] = remainingToPlace.remove(at: safeIdx)
            } else {
                // if only matching element remains (edge case with 1 item), place it anyway
                // UI will still work; alternatively, leave nil if chcesz unikać pewnej pary.
                newRight[i] = remainingToPlace.isEmpty ? nil : remainingToPlace.removeFirst()
            }
        }
        
        rightItems = newRight
    }
}

