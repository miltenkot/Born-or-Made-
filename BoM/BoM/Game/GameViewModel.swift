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
    
    // Source data
    let qaItems: [QAItem] = [
        QAItem(question: "Capital of France", answer: "Paris"),
        QAItem(question: "1 + 1", answer: "2"),
        QAItem(question: "Color of the sky", answer: "Blue"),
        QAItem(question: "Programming language used for iOS apps", answer: "Swift"),
        QAItem(question: "Leap year has", answer: "366 days"),
        QAItem(question: "Capital of Germany", answer: "Berlin"),
        QAItem(question: "3 * 3", answer: "9"),
        QAItem(question: "Capital of Italy", answer: "Rome"),
        QAItem(question: "Author of 'Pan Tadeusz'", answer: "Adam Mickiewicz"),
        QAItem(question: "Square root of 16", answer: "4"),
        QAItem(question: "Color of grass", answer: "Green"),
        QAItem(question: "Apple's mobile operating system", answer: "iOS"),
        QAItem(question: "Capital of Spain", answer: "Madrid"),
        QAItem(question: "5 - 2", answer: "3"),
        QAItem(question: "Capital of Poland", answer: "Warsaw"),
        QAItem(question: "71 + 5", answer: "76"),
        QAItem(question: "Color of blood", answer: "Red"),
        QAItem(question: "Number of months in a year", answer: "12"),
        QAItem(question: "Hours in a day", answer: "24 hours"),
        QAItem(question: "Capital of Portugal", answer: "Lisbon")
    ]
    
    // Game state
    var leftItems: [QAItem?] = []
    var rightItems: [QAItem?] = []
    
    // Remaining items pool for refilling
    private var remainingItems: [QAItem] = []
    
    var selectedLeftIndex: Int? = nil
    var selectedRightIndex: Int? = nil
    
    // Frozen slots to prevent user taps
    private(set) var frozenLeft: Set<Int> = []
    private(set) var frozenRight: Set<Int> = []
    
    // Indices to highlight mismatches (red border)
    private(set) var mismatchLeftIndex: Int? = nil
    private(set) var mismatchRightIndex: Int? = nil
    
    // Indices to highlight matches (green border)
    private(set) var matchLeftIndex: Int? = nil
    private(set) var matchRightIndex: Int? = nil
    
    // Round identifier to cancel async operations if round changes
    private var roundID = UUID()
    
    // Computed properties
    var visibleRowsCount: Int { min(qaItems.count, maxVisibleRows) }
    var rowsCount: Int { visibleRowsCount }
    
    // Check if current selection is a correct match
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
    
    // Global lock to prevent all interactions
    private(set) var isInteractionLocked: Bool = false
    
    // MARK: - Setup
    func setupRound() {
        roundID = UUID() // Cancel any in-flight async operations
        let shuffled = qaItems.shuffled()
        
        leftItems = Array(repeating: nil, count: maxVisibleRows)
        rightItems = Array(repeating: nil, count: maxVisibleRows)
        
        let take = min(visibleRowsCount, shuffled.count)
        for i in 0..<take {
            leftItems[i] = shuffled[i]
        }
        remainingItems = shuffled.count > take ? Array(shuffled.dropFirst(take)) : []
        
        rebuildRightPreservingStableSlots()
        
        selectedLeftIndex = nil
        selectedRightIndex = nil
        frozenLeft.removeAll()
        frozenRight.removeAll()
        mismatchLeftIndex = nil
        mismatchRightIndex = nil
        matchLeftIndex = nil
        matchRightIndex = nil
    }
    
    // MARK: - Selection helpers
    func isLeftSelected(_ row: Int) -> Bool { selectedLeftIndex == row }
    func isRightSelected(_ row: Int) -> Bool { selectedRightIndex == row }
    func isLeftFrozen(_ row: Int) -> Bool { frozenLeft.contains(row) }
    func isRightFrozen(_ row: Int) -> Bool { frozenRight.contains(row) }
    func isLeftMismatch(_ row: Int) -> Bool { mismatchLeftIndex == row }
    func isRightMismatch(_ row: Int) -> Bool { mismatchRightIndex == row }
    func isLeftMatch(_ row: Int) -> Bool { matchLeftIndex == row }
    func isRightMatch(_ row: Int) -> Bool { matchRightIndex == row }
    
    // Determine selection colors (border + background)
    func selectionColors(isSelected: Bool, isMismatch: Bool = false, isMatch: Bool = false) -> (border: Color, background: Color) {
        if isMismatch { return (.red, Color.red.opacity(0.15)) }
        if isMatch { return (.green, Color.green.opacity(0.25)) }
        guard isSelected else { return (.blue, Color.blue.opacity(0.2)) }
        return isCurrentSelectionMatching ? (.green, Color.green.opacity(0.25)) : (.blue, Color.blue.opacity(0.15))
    }
    
    func selectionColor(isSelected: Bool, isMismatch: Bool = false, isMatch: Bool = false) -> Color {
        selectionColors(isSelected: isSelected, isMismatch: isMismatch, isMatch: isMatch).border
    }
    
    func selectionBackgroundColor(isSelected: Bool, isMismatch: Bool = false, isMatch: Bool = false) -> Color {
        selectionColors(isSelected: isSelected, isMismatch: isMismatch, isMatch: isMatch).background
    }
    
    // Toggle selection
    func toggleLeftSelection(_ row: Int) {
        guard !isLeftFrozen(row), !isInteractionLocked else { return }
        selectedLeftIndex = (selectedLeftIndex == row) ? nil : row
    }
    
    func toggleRightSelection(_ row: Int) {
        guard !isRightFrozen(row), !isInteractionLocked else { return }
        selectedRightIndex = (selectedRightIndex == row) ? nil : row
    }
    
    // MARK: - Confirm selection
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
        
        // Handle mismatch
        guard leftItem.id == rightItem.id else {
            mismatchLeftIndex = li
            mismatchRightIndex = ri
            
            // Lock all interactions
            isInteractionLocked = true
            
            selectedLeftIndex = nil
            selectedRightIndex = nil
            
            guard currentRound == roundID else { return }
            
            try? await Task.sleep(for: .seconds(1))
            
            guard currentRound == roundID else { return }
            
            mismatchLeftIndex = nil
            mismatchRightIndex = nil
            isInteractionLocked = false
            return
        }
        
        // Handle match
        frozenLeft.insert(li)
        frozenRight.insert(ri)
        matchLeftIndex = li
        matchRightIndex = ri
        selectedLeftIndex = nil
        selectedRightIndex = nil
        
        try? await Task.sleep(for: .seconds(1))
        guard currentRound == roundID else { return }
        
        let disappearDuration = Double(Int.random(in: 1...3))
        leftItems[li] = nil
        rightItems[ri] = nil
        matchLeftIndex = nil
        matchRightIndex = nil
        
        guard currentRound == roundID else { return }
        
        var emptyLeftIndices = (0..<maxVisibleRows).filter { leftItems[$0] == nil }
        emptyLeftIndices.shuffle()
        while !remainingItems.isEmpty, !emptyLeftIndices.isEmpty {
            withAnimation(.easeInOut(duration: disappearDuration)) {
                let idx = emptyLeftIndices.removeFirst()
                leftItems[idx] = remainingItems.popLast()
            }
        }
        
        withAnimation(.easeInOut(duration: disappearDuration)) {
            rebuildRightPreservingStableSlots()
        }
        
        guard currentRound == roundID else { return }
        frozenLeft.remove(li)
        frozenRight.remove(ri)
    }
    
    // MARK: - Right column rebuild
    private func rebuildRightPreservingStableSlots() {
        let desired = leftItems.compactMap { $0 }
        var remainingToPlace = desired
        var newRight: [QAItem?] = Array(repeating: nil, count: maxVisibleRows)
        
        // Preserve stable slots from previous rightItems
        for i in 0..<maxVisibleRows {
            guard let leftAtI = leftItems[i] else { continue }
            if rightItems.indices.contains(i), let currentRight = rightItems[i] {
                if let idx = remainingToPlace.firstIndex(of: currentRight) {
                    remainingToPlace.remove(at: idx)
                }
                if currentRight.id != leftAtI.id {
                    newRight[i] = currentRight
                }
            }
        }
        
        // Fill empty right slots avoiding direct matches
        remainingToPlace.shuffle()
        for i in 0..<maxVisibleRows {
            guard newRight[i] == nil, let leftAtI = leftItems[i] else { continue }
            if let safeIdx = remainingToPlace.firstIndex(where: { $0.id != leftAtI.id }) {
                newRight[i] = remainingToPlace.remove(at: safeIdx)
            } else if !remainingToPlace.isEmpty {
                let matchingItem = remainingToPlace.removeFirst()
                newRight[i] = matchingItem
                
                // Attempt to swap with previous row to avoid immediate match
                if let k = (0..<i).first(where: { k in
                    guard let kItem = newRight[k], let kLeft = leftItems[k] else { return false }
                    if matchingItem.id == kLeft.id { return false }
                    if kItem.id == leftAtI.id { return false }
                    return true
                }) {
                    newRight.swapAt(i, k)
                }
            }
        }
        
        // Fill any remaining empty slots
        for i in 0..<maxVisibleRows where newRight[i] == nil {
            if let next = remainingToPlace.popLast() {
                newRight[i] = next
            }
        }
        
        rightItems = newRight
    }
}

// MARK: - Array safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
