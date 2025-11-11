//
//  BoMTests.swift
//  BoMTests
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import Testing
@testable import BoM
import SwiftUI

@Suite("GameViewModel tests")
struct GameViewModelTests {
    
    // Helper to assert that rightItems is a permutation of non-nil left items
    @MainActor private func assertRightIsPermutationOfLeft(_ model: GameViewModel, file: StaticString = #filePath, line: UInt = #line) {
        let left = model.roundItems.compactMap { $0 }
        let right = model.rightItems.compactMap { $0 }
        // Same counts
        #expect(left.count == right.count, "Right should contain same number of non-nil items as left.")
        // Same multiset by id
        let leftIDs = left.map(\.id).sorted { $0.uuidString < $1.uuidString }
        let rightIDs = right.map(\.id).sorted { $0.uuidString < $1.uuidString }
        #expect(leftIDs == rightIDs, "Right should be a permutation of left by identity.")
    }
    
    // Helper to assert no same-index matches when avoidable
    @MainActor private func assertNoSameIndexMatchesWhenPossible(_ model: GameViewModel, file: StaticString = #filePath, line: UInt = #line) {
        // Count how many indices have both sides non-nil
        var clashCount = 0
        var nonNilPairs = 0
        for i in 0..<model.fixedRows {
            if let l = model.roundItems[i], let r = model.rightItems[i] {
                nonNilPairs += 1
                if l.id == r.id {
                    clashCount += 1
                }
            }
        }
        // If there are at least 2 items, we should generally be able to avoid clashes.
        // With 0 or 1 item, clashes may be unavoidable.
        if nonNilPairs >= 2 {
            #expect(clashCount == 0, "Same-index matches should be avoided when possible.")
        }
    }
    
    @Test("setupRound initializes arrays and right is a permutation of left")
    @MainActor
    func testSetupRoundInitialization() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Arrays sized to fixedRows
        #expect(model.roundItems.count == model.fixedRows)
        #expect(model.rightItems.count == model.fixedRows)
        
        // Left filled up to rowsCount
        let nonNilLeft = model.roundItems.compactMap { $0 }
        #expect(nonNilLeft.count == model.rowsCount)
        
        // Selections cleared
        #expect(model.selectedLeftIndex == nil)
        #expect(model.selectedRightIndex == nil)
        
        // Right is permutation of left and avoids same-index matches when possible
        assertRightIsPermutationOfLeft(model)
        assertNoSameIndexMatchesWhenPossible(model)
    }
    
    @Test("Selection toggling and selectionColor")
    @MainActor
    func testSelectionToggleAndColor() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Pick a valid left row
        let leftRow = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil })!
        // Initially not selected
        #expect(model.isLeftSelected(leftRow) == false)
        
        model.toggleLeftSelection(leftRow)
        #expect(model.isLeftSelected(leftRow) == true)
        
        // Color should be blue unless a correct pair is selected simultaneously
        let colorWhenOnlyLeftSelected = model.selectionColor(isSelected: model.isLeftSelected(leftRow))
        #expect(colorWhenOnlyLeftSelected == Color.blue)
        
        // Toggle again to deselect
        model.toggleLeftSelection(leftRow)
        #expect(model.isLeftSelected(leftRow) == false)
        
        // Do the same for right
        let rightRow = (0..<model.fixedRows).first(where: { model.rightItems[$0] != nil })!
        #expect(model.isRightSelected(rightRow) == false)
        model.toggleRightSelection(rightRow)
        #expect(model.isRightSelected(rightRow) == true)
        let colorWhenOnlyRightSelected = model.selectionColor(isSelected: model.isRightSelected(rightRow))
        #expect(colorWhenOnlyRightSelected == Color.blue)
    }
    
    @Test("isCurrentSelectionMatching reflects id equality")
    @MainActor
    func testIsCurrentSelectionMatching() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Find a matching pair by id across columns
        // Build a map from right id to index
        var rightIndexByID: [UUID: Int] = [:]
        for i in 0..<model.fixedRows {
            if let r = model.rightItems[i] {
                rightIndexByID[r.id] = i
            }
        }
        
        // For the first non-nil left, find its matching right index
        guard
            let leftIndex = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil }),
            let leftItem = model.roundItems[leftIndex],
            let matchingRightIndex = rightIndexByID[leftItem.id]
        else {
            Issue.record("Could not find a matching pair to test.")
            return
        }
        
        // Select a non-matching right first
        if let nonMatchingRightIndex = (0..<model.fixedRows).first(where: {
            $0 != matchingRightIndex && model.rightItems[$0] != nil
        }) {
            model.toggleLeftSelection(leftIndex)
            model.toggleRightSelection(nonMatchingRightIndex)
            #expect(model.isCurrentSelectionMatching == false)
            // clear
            model.toggleLeftSelection(leftIndex)
            model.toggleRightSelection(nonMatchingRightIndex)
        }
        
        // Now select the true matching pair
        model.toggleLeftSelection(leftIndex)
        model.toggleRightSelection(matchingRightIndex)
        #expect(model.isCurrentSelectionMatching == true)
    }
    
    @Test("confirmSelectionIfMatching replaces only matched left slot, rebuilds right, and clears selection")
    @MainActor
    func testConfirmSelectionIfMatching() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Find a matching pair indices by id
        var rightIndexByID: [UUID: Int] = [:]
        for i in 0..<model.fixedRows {
            if let r = model.rightItems[i] {
                rightIndexByID[r.id] = i
            }
        }
        
        guard
            let leftIndex = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil }),
            let leftItem = model.roundItems[leftIndex],
            let rightIndex = rightIndexByID[leftItem.id]
        else {
            Issue.record("Could not find a matching pair to test.")
            return
        }
        
        // Capture state before confirmation
        let beforeLeft = model.roundItems
        _ = model.rightItems
        
        // Select and confirm
        model.toggleLeftSelection(leftIndex)
        model.toggleRightSelection(rightIndex)
        #expect(model.isCurrentSelectionMatching == true)
        
        model.confirmSelectionIfMatching()
        
        // Selections cleared
        #expect(model.selectedLeftIndex == nil)
        #expect(model.selectedRightIndex == nil)
        
        // Only the leftIndex slot should have changed (either replaced with new item or nil if pool empty)
        for i in 0..<model.fixedRows {
            if i == leftIndex {
                // Expect either nil or a different item id
                let old = beforeLeft[i]
                let new = model.roundItems[i]
                if let old, let new {
                    #expect(old.id != new.id, "Matched left slot should be replaced with a new item when available.")
                } else {
                    // nil is acceptable when pool exhausted
                    #expect(true)
                }
            } else {
                #expect(model.roundItems[i] == beforeLeft[i], "Other left slots should remain unchanged.")
            }
        }
        
        // Right rebuilt: permutation of current left and avoiding same-index matches when possible
        assertRightIsPermutationOfLeft(model)
        assertNoSameIndexMatchesWhenPossible(model)
    }
    
    @Test("Edge case: when only one item remains, right may align with same index")
    @MainActor
    func testSingleItemEdgeCase() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Consume matches until only one non-nil left remains
        func nonNilLeftIndices() -> [Int] {
            (0..<model.fixedRows).filter { model.roundItems[$0] != nil }
        }
        
        while nonNilLeftIndices().count > 1 {
            // For a current left index, find matching right index
            let li = nonNilLeftIndices().first!
            let id = model.roundItems[li]!.id
            let ri = (0..<model.fixedRows).first(where: { model.rightItems[$0]?.id == id })!
            model.toggleLeftSelection(li)
            model.toggleRightSelection(ri)
            model.confirmSelectionIfMatching()
        }
        
        // Now only one left item remains
        let remainingIndex = nonNilLeftIndices().first!
        // Right may or may not align at the same index; just ensure permutation holds
        assertRightIsPermutationOfLeft(model)
        // If same index aligns, it is acceptable in this edge case
        // No assertion on same-index avoidance here.
        _ = remainingIndex
    }
}
