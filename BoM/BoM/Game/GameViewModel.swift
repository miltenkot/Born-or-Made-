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
    
    // Source data
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
    
    // Newly added: frozen indices to disable taps temporarily
    private(set) var frozenLeft: Set<Int> = []
    private(set) var frozenRight: Set<Int> = []
    
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
        remainingItems = qaItems.shuffled()
        roundItems = Array(repeating: nil, count: fixedRows)
        rightItems = Array(repeating: nil, count: fixedRows)
        
        for i in 0..<rowsCount {
            if let next = remainingItems.first {
                roundItems[i] = next
                remainingItems.removeFirst()
            }
        }
        rebuildRightPreservingStableSlots()
        selectedLeftIndex = nil
        selectedRightIndex = nil
        frozenLeft.removeAll()
        frozenRight.removeAll()
    }
    
    func isLeftSelected(_ row: Int) -> Bool {
        selectedLeftIndex == row
    }
    
    func isRightSelected(_ row: Int) -> Bool {
        selectedRightIndex == row
    }
    
    func isLeftFrozen(_ row: Int) -> Bool {
        frozenLeft.contains(row)
    }
    
    func isRightFrozen(_ row: Int) -> Bool {
        frozenRight.contains(row)
    }
    
    func selectionColor(isSelected: Bool) -> Color {
        (isSelected && isCurrentSelectionMatching) ? .green : .blue
    }
    
    func selectionBackgroundColor(isSelected: Bool) -> Color {
        guard isSelected else { return Color.blue.opacity(0.2) }
        return isCurrentSelectionMatching
            ? Color.green.opacity(0.25)
            : Color.blue.opacity(0.15)
    }
    
    func toggleLeftSelection(_ row: Int) {
        guard !isLeftFrozen(row) else { return }
        selectedLeftIndex = (selectedLeftIndex == row) ? nil : row
    }
    
    func toggleRightSelection(_ row: Int) {
        guard !isRightFrozen(row) else { return }
        selectedRightIndex = (selectedRightIndex == row) ? nil : row
    }
    
    // Call after both sides are selected to handle match and refill with delays and animations
    func confirmSelectionIfMatching() async {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            roundItems.indices.contains(li),
            rightItems.indices.contains(ri),
            let leftItem = roundItems[li],
            let rightItem = rightItems[ri]
        else { return }
        
        // Check match by identity
        guard leftItem.id == rightItem.id else {
            return
        }
        
        // Freeze both cells to disable interactions
        frozenLeft.insert(li)
        frozenRight.insert(ri)
        
        // Clear selection immediately so UI nie sugeruje kolejnych akcji
        selectedLeftIndex = nil
        selectedRightIndex = nil
        
        // Random freeze duration: 1..3 seconds
        let freezeSeconds = Double(Int.random(in: 1...3))
        try? await Task.sleep(nanoseconds: UInt64(freezeSeconds * 1_000_000_000))
        
        // Remove matched items (both sides) with animation
        withAnimation(.easeInOut) {
            roundItems[li] = nil
            rightItems[ri] = nil
        }
        
        // Unfreeze both slots
        frozenLeft.remove(li)
        frozenRight.remove(ri)
        
        // After 1 second, insert new items in random empty slots (if any remain)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Collect empty indices on the left
        let emptyLeftIndices = (0..<fixedRows).filter { roundItems[$0] == nil }
        // Fill empty left slots with new items randomly
        var shuffledEmptyLeft = emptyLeftIndices.shuffled()
        while !remainingItems.isEmpty, !shuffledEmptyLeft.isEmpty {
            let idx = shuffledEmptyLeft.removeFirst()
            withAnimation(.spring) {
                roundItems[idx] = remainingItems.removeFirst()
            }
        }
        
        // Rebuild right side permutation to reflect current left, preserving stability where possible
        withAnimation(.easeInOut) {
            rebuildRightPreservingStableSlots()
        }
    }
    
    // MARK: - Right column rebuild preserving stable slots
    private func rebuildRightPreservingStableSlots() {
        let desired = roundItems.compactMap { $0 }
        var remainingToPlace = desired
        
        var newRight: [QAItem?] = Array(repeating: nil, count: fixedRows)
        for i in 0..<fixedRows {
            guard let leftAtI = roundItems[i] else {
                continue
            }
            if let currentRight = rightItems.indices.contains(i) ? rightItems[i] : nil,
               let idx = remainingToPlace.firstIndex(of: currentRight),
               currentRight.id != leftAtI.id {
                newRight[i] = currentRight
                remainingToPlace.remove(at: idx)
            }
        }
        
        remainingToPlace.shuffle()
        for i in 0..<fixedRows {
            guard newRight[i] == nil, let leftAtI = roundItems[i] else { continue }
            if let safeIdx = remainingToPlace.firstIndex(where: { $0.id != leftAtI.id }) {
                newRight[i] = remainingToPlace.remove(at: safeIdx)
            } else {
                newRight[i] = remainingToPlace.isEmpty ? nil : remainingToPlace.removeFirst()
            }
        }
        
        rightItems = newRight
    }
}

