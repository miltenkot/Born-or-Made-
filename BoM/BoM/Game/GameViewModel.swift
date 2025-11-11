//
//  GameViewModel.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//  Updated by ChatGPT (nate) - applied robustness & readability fixes.
//

import SwiftUI
import Observation

// NOTE: QAItem musi być zdefiniowany gdzie indziej w projekcie i mieć unikalne `id`.
@MainActor
@Observable
final class GameViewModel {
    // Layout configuration
    let spacing: CGFloat = 12
    let horizontalPadding: CGFloat = 16
    let verticalPadding: CGFloat = 16
    let maxVisibleRows: Int = 5
    
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
        QAItem(question: "71 + 5", answer: "76"),
        QAItem(question: "Kolor krwi", answer: "Czerwony"),
        QAItem(question: "Liczba miesięcy w roku", answer: "12"),
        QAItem(question: "Doba ma", answer: "24 godziny"),
        QAItem(question: "Stolica Portugalii", answer: "Lizbona")
    ]
    
    // Game state
    var leftItems: [QAItem?] = []
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
    
    // Round identifier to protect against race conditions when awaiting sleeps/animations
    private var roundID = UUID()
    
    // Computed properties
    var visibleRowsCount: Int { min(qaItems.count, maxVisibleRows) }
    
    var rowsCount: Int { visibleRowsCount } // backward-compatibility if używane gdzieś indziej
    
    var isCurrentSelectionMatching: Bool {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            leftItems.indices.contains(li),
            rightItems.indices.contains(ri),
            let l = leftItems[li],
            let r = rightItems[ri]
        else { return false }
        return l.id == r.id
    }
    
    // API
    func setupRound() {
        roundID = UUID() // bump round id to cancel in-flight async operations
        let shuffled = qaItems.shuffled()
        // Fill left with first visibleRowsCount, remaining into remainingItems
        leftItems = Array(repeating: nil, count: maxVisibleRows)
        rightItems = Array(repeating: nil, count: maxVisibleRows)
        
        let take = min(visibleRowsCount, shuffled.count)
        for i in 0..<take {
            leftItems[i] = shuffled[i]
        }
        if shuffled.count > take {
            remainingItems = Array(shuffled.dropFirst(take))
        } else {
            remainingItems = []
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
    
    // New single source for selection colors (border + background)
    func selectionColors(isSelected: Bool, isMismatch: Bool = false) -> (border: Color, background: Color) {
        if isMismatch { return (.red, Color.red.opacity(0.15)) }
        guard isSelected else { return (.blue, Color.blue.opacity(0.2)) }
        return isCurrentSelectionMatching
        ? (.green, Color.green.opacity(0.25))
        : (.blue, Color.blue.opacity(0.15))
    }
    
    // Backwards-compatible helpers (jeśli UI używał ich wcześniej)
    func selectionColor(isSelected: Bool, isMismatch: Bool = false) -> Color {
        selectionColors(isSelected: isSelected, isMismatch: isMismatch).border
    }
    
    func selectionBackgroundColor(isSelected: Bool, isMismatch: Bool = false) -> Color {
        selectionColors(isSelected: isSelected, isMismatch: isMismatch).background
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
            leftItems.indices.contains(li),
            rightItems.indices.contains(ri),
            let leftItem = leftItems[li],
            let rightItem = rightItems[ri]
        else { return }
        
        let currentRound = roundID
        
        // Mismatch: freeze only these two for ~2s, show red state
        guard leftItem.id == rightItem.id else {
            mismatchLeftIndex = li
            mismatchRightIndex = ri
            frozenLeft.insert(li)
            frozenRight.insert(ri)
            selectedLeftIndex = nil
            selectedRightIndex = nil
            
            // wait but respect round cancellation
            //try? await Task.sleep(for: .seconds(2))
            guard currentRound == roundID else { return }
            
            frozenLeft.remove(li)
            frozenRight.remove(ri)
            withAnimation(.easeInOut(duration: 2)) {
                mismatchLeftIndex = nil
                mismatchRightIndex = nil
            }
            return
        }
        
        // Match: freeze only the two clicked slots until new data appears and finishes appearing
        frozenLeft.insert(li)
        frozenRight.insert(ri)
        selectedLeftIndex = nil
        selectedRightIndex = nil
        
        try? await Task.sleep(for: .seconds(1))
        
        // Shared random timing for disappearance
        let disappearDuration = Double(Int.random(in: 1...3))
        
        // Disappear both sides together
        leftItems[li] = nil
        rightItems[ri] = nil

        guard currentRound == roundID else { return }
        
        // Refill left empty slots from remainingItems
        var emptyLeftIndices = (0..<maxVisibleRows).filter { leftItems[$0] == nil }
        emptyLeftIndices.shuffle()
        while !remainingItems.isEmpty, !emptyLeftIndices.isEmpty {
            withAnimation(.easeInOut(duration: disappearDuration)) {
                let idx = emptyLeftIndices.removeFirst()
                leftItems[idx] = remainingItems.popLast()
            }
        }
        
        // Rebuild right as permutation of left
        withAnimation(.easeInOut(duration: disappearDuration)) {
            rebuildRightPreservingStableSlots()
        }
        
        guard currentRound == roundID else { return }
        
        frozenLeft.remove(li)
        frozenRight.remove(ri)
    }
    
    // MARK: - Right column rebuild preserving stable slots (improved & robust)
    private func rebuildRightPreservingStableSlots() {
        // Desired set: only the non-nil left items
        let desired = leftItems.compactMap { $0 }
        
        // Remaining to place initially includes all desired items
        var remainingToPlace = desired
        
        var newRight: [QAItem?] = Array(repeating: nil, count: maxVisibleRows)
        
        // Stage 1: Preserve "stable" items from previous rightItems if possible.
        // Regardless whether they match left or not, remove them from remainingToPlace to avoid duplicates.
        for i in 0..<maxVisibleRows {
            guard let leftAtI = leftItems[i] else { continue }
            if rightItems.indices.contains(i), let currentRight = rightItems[i] {
                if let idx = remainingToPlace.firstIndex(of: currentRight) {
                    // Remove from pool so we don't duplicate it later.
                    remainingToPlace.remove(at: idx)
                }
                // If currentRight does NOT match leftAtI, keep it in this slot (stability).
                if currentRight.id != leftAtI.id {
                    newRight[i] = currentRight
                }
                // If it matched leftAtI, we intentionally don't place it (to avoid immediate match).
                // but it's already removed from remainingToPlace so it cannot appear twice.
            }
        }
        
        // Stage 2: Shuffle remaining pool and try to fill empty right slots with items that don't match left in same row.
        remainingToPlace.shuffle()
        for i in 0..<maxVisibleRows {
            guard newRight[i] == nil, let leftAtI = leftItems[i] else { continue }
            
            // Try to find an item in remainingToPlace that does NOT match leftAtI
            if let safeIdx = remainingToPlace.firstIndex(where: { $0.id != leftAtI.id }) {
                newRight[i] = remainingToPlace.remove(at: safeIdx)
            } else if !remainingToPlace.isEmpty {
                // Edge case: only items left match the left side for this row.
                // Place one, but then attempt to swap with a previous row to avoid direct match.
                let matchingItem = remainingToPlace.removeFirst()
                newRight[i] = matchingItem
                
                // Try to find a previous index k we can swap with to avoid both matches
                if let k = (0..<i).first(where: { k in
                    guard let kItem = newRight[k], let kLeft = leftItems[k] else { return false }
                    // Can't swap if new item (=matchingItem) would match left at k
                    if matchingItem.id == kLeft.id { return false }
                    // Can't swap if kItem would match left at i
                    if kItem.id == leftAtI.id { return false }
                    return true
                }) {
                    newRight.swapAt(i, k)
                }
            }
        }
        
        // Stage 3: If there are still items left in remainingToPlace (rare), fill any remaining empty slots ignoring the match rule.
        for i in 0..<maxVisibleRows where newRight[i] == nil {
            if let next = remainingToPlace.popLast() {
                newRight[i] = next
            }
        }
        
        rightItems = newRight
    }
}

// MARK: - Array safe subscript helper

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
