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
        QAItem(question: "1 + 1", answer: "2"),
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
    
    // Per-slot freeze to disable taps on specific cells
    private(set) var frozenLeft: Set<Int> = []
    private(set) var frozenRight: Set<Int> = []
    
    // Indices to highlight a mismatch with a red border
    private(set) var mismatchLeftIndex: Int? = nil
    private(set) var mismatchRightIndex: Int? = nil
    
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
        mismatchLeftIndex = nil
        mismatchRightIndex = nil
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
    
    // Whether a given row should show a mismatch (red) state
    func isLeftMismatch(_ row: Int) -> Bool {
        mismatchLeftIndex == row
    }
    
    func isRightMismatch(_ row: Int) -> Bool {
        mismatchRightIndex == row
    }
    
    func selectionColor(isSelected: Bool, isMismatch: Bool = false) -> Color {
        if isMismatch { return .red }
        return (isSelected && isCurrentSelectionMatching) ? .green : .blue
    }
    
    func selectionBackgroundColor(isSelected: Bool, isMismatch: Bool = false) -> Color {
        if isMismatch { return Color.red.opacity(0.15) }
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
    
    // Call after both sides are selected to handle match, mismatch, and refilling with delays and animations
    func confirmSelectionIfMatching() async {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            roundItems.indices.contains(li),
            rightItems.indices.contains(ri),
            let leftItem = roundItems[li],
            let rightItem = rightItems[ri]
        else { return }
        
        // Mismatch: freeze only these two for ~2s, show red state
        guard leftItem.id == rightItem.id else {
            mismatchLeftIndex = li
            mismatchRightIndex = ri
            frozenLeft.insert(li)
            frozenRight.insert(ri)
            selectedLeftIndex = nil
            selectedRightIndex = nil
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            frozenLeft.remove(li)
            frozenRight.remove(ri)
            mismatchLeftIndex = nil
            mismatchRightIndex = nil
            return
        }
        
        // Match: freeze only the two clicked slots until new data appears and finishes appearing
        frozenLeft.insert(li)
        frozenRight.insert(ri)
        selectedLeftIndex = nil
        selectedRightIndex = nil
        
        // Shared random timing for disappearance
        let disappearDuration = Double(Int.random(in: 1...3))
        let appearDuration = 0.35
        
        // Disappear both sides together
        withAnimation(.easeInOut(duration: disappearDuration)) {
            roundItems[li] = nil
            rightItems[ri] = nil
        }
        try? await Task.sleep(nanoseconds: UInt64(disappearDuration * 1_000_000_000))
        
        // Refill left empty slots
        let emptyLeftIndices = (0..<fixedRows).filter { roundItems[$0] == nil }
        var shuffledEmptyLeft = emptyLeftIndices.shuffled()
        while !remainingItems.isEmpty, !shuffledEmptyLeft.isEmpty {
            let idx = shuffledEmptyLeft.removeFirst()
            roundItems[idx] = remainingItems.removeFirst()
        }
        
        // Rebuild right as permutation of left
        rebuildRightPreservingStableSlots()
        
        // Animate appearance (both sides same timing)
        withAnimation(.easeInOut(duration: appearDuration)) {
            // values already set; block provides consistent timing
        }
        try? await Task.sleep(nanoseconds: UInt64(appearDuration * 1_000_000_000))
        
        // Now that new data is visible, unlock only these two slots
        frozenLeft.remove(li)
        frozenRight.remove(ri)
    }
    
    // MARK: - Right column rebuild preserving stable slots
    private func rebuildRightPreservingStableSlots() {
        let desired = roundItems.compactMap { $0 }
        var remainingToPlace = desired
        
        var newRight: [QAItem?] = Array(repeating: nil, count: fixedRows)
        for i in 0..<fixedRows {
            guard let leftAtI = roundItems[i] else { continue }
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
