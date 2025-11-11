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
    
    // Helper: assert that rightItems is a permutation of non-nil left items
    @MainActor private func assertRightIsPermutationOfLeft(_ model: GameViewModel) {
        let left = model.roundItems.compactMap { $0 }
        let right = model.rightItems.compactMap { $0 }
        #expect(left.count == right.count, "Right should contain same number of non-nil items as left.")
        let leftIDs = left.map(\.id).sorted { $0.uuidString < $1.uuidString }
        let rightIDs = right.map(\.id).sorted { $0.uuidString < $1.uuidString }
        #expect(leftIDs == rightIDs, "Right should be a permutation of left by identity.")
    }
    
    // Helper: determine if avoiding same-index matches is theoretically possible (approximation)
    @MainActor private func canAvoidSameIndexMatches(_ model: GameViewModel) -> Bool {
        // Map: item id -> indices where it appears on the right
        var rightIndicesByID: [UUID: [Int]] = [:]
        for i in 0..<model.fixedRows {
            if let r = model.rightItems[i] {
                rightIndicesByID[r.id, default: []].append(i)
            }
        }
        var unavoidableClashes = 0
        var totalPairs = 0
        for i in 0..<model.fixedRows {
            guard let l = model.roundItems[i] else { continue }
            totalPairs += 1
            let candidates = rightIndicesByID[l.id, default: []]
            if candidates.contains(i) && candidates.count == 1 {
                unavoidableClashes += 1
            }
        }
        if totalPairs <= 1 { return false }
        return unavoidableClashes == 0
    }
    
    // Helper: assert to avoid same-index matches when approximation says it's avoidable
    @MainActor private func assertNoSameIndexMatchesWhenApproxAvoidable(_ model: GameViewModel) {
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
        if nonNilPairs >= 2 && canAvoidSameIndexMatches(model) {
            #expect(clashCount == 0, "Same-index matches should be avoided when it's plausibly avoidable.")
        } else {
            #expect(true)
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
        
        // Right is permutation of left and avoids same-index matches when plausibly avoidable
        assertRightIsPermutationOfLeft(model)
        assertNoSameIndexMatchesWhenApproxAvoidable(model)
    }
    
    @Test("Selection toggling and selectionColor")
    @MainActor
    func testSelectionToggleAndColor() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Pick a valid left row
        let leftRow = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil })!
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
    
    @Test("confirmSelectionIfMatching (match): replaces only matched left slot, rebuilds right, and clears selection")
    @MainActor
    func testConfirmSelectionIfMatching_Match() async throws {
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
        
        // Select and confirm
        model.toggleLeftSelection(leftIndex)
        model.toggleRightSelection(rightIndex)
        #expect(model.isCurrentSelectionMatching == true)
        
        await model.confirmSelectionIfMatching()
        
        // Selections cleared
        #expect(model.selectedLeftIndex == nil)
        #expect(model.selectedRightIndex == nil)
        
        // Only the leftIndex slot should have changed (either replaced with new item or nil if pool empty)
        for i in 0..<model.fixedRows {
            if i == leftIndex {
                let old = beforeLeft[i]
                let new = model.roundItems[i]
                if let old, let new {
                    #expect(old.id != new.id, "Matched left slot should be replaced with a new item when available.")
                } else {
                    #expect(true) // nil acceptable when pool exhausted
                }
            } else {
                #expect(model.roundItems[i] == beforeLeft[i], "Other left slots should remain unchanged.")
            }
        }
        
        // Right rebuilt: permutation of current left and avoid same-index when plausibly avoidable
        assertRightIsPermutationOfLeft(model)
        assertNoSameIndexMatchesWhenApproxAvoidable(model)
    }
    
    @Test("confirmSelectionIfMatching (mismatch): shows red state, freezes only the two slots for ~2s, clears selections immediately, then clears mismatch and unfreezes")
    @MainActor
    func testConfirmSelectionIfMatching_Mismatch() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Find a left index and a non-matching right index
        var rightIndicesByID: [UUID: [Int]] = [:]
        for i in 0..<model.fixedRows {
            if let r = model.rightItems[i] {
                rightIndicesByID[r.id, default: []].append(i)
            }
        }
        
        guard
            let leftIndex = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil }),
            let leftItem = model.roundItems[leftIndex]
        else {
            Issue.record("No left item to test mismatch.")
            return
        }
        
        // Choose any right index with a different id
        guard
            let nonMatchingRightIndex = (0..<model.fixedRows).first(where: {
                if let r = model.rightItems[$0] { return r.id != leftItem.id }
                return false
            })
        else {
            Issue.record("Could not find a non-matching right index to test mismatch.")
            return
        }
        
        // Select and confirm mismatch
        model.toggleLeftSelection(leftIndex)
        model.toggleRightSelection(nonMatchingRightIndex)
        #expect(model.isCurrentSelectionMatching == false)
        
        // Fire async mismatch handling
        Task { await model.confirmSelectionIfMatching() }
        
        // Immediately after call, selections should be cleared and mismatch flags set, both slots frozen
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(model.selectedLeftIndex == nil)
        #expect(model.selectedRightIndex == nil)
        #expect(model.isLeftMismatch(leftIndex) == true)
        #expect(model.isRightMismatch(nonMatchingRightIndex) == true)
        #expect(model.isLeftFrozen(leftIndex) == true)
        #expect(model.isRightFrozen(nonMatchingRightIndex) == true)
        
        // After ~2s, mismatch should clear and slots should unfreeze
        try? await Task.sleep(nanoseconds: 2_200_000_000) // 2.2s to be safe
        #expect(model.isLeftMismatch(leftIndex) == false)
        #expect(model.isRightMismatch(nonMatchingRightIndex) == false)
        #expect(model.isLeftFrozen(leftIndex) == false)
        #expect(model.isRightFrozen(nonMatchingRightIndex) == false)
    }
    
    @Test("Only mismatched slots are disabled; other slots remain interactive during mismatch penalty")
    @MainActor
    func testOnlyMismatchedSlotsDisabled() async throws {
        let model = GameViewModel()
        model.setupRound()
        
        // Pick a mismatch pair
        guard
            let leftIndex = (0..<model.fixedRows).first(where: { model.roundItems[$0] != nil }),
            let leftItem = model.roundItems[leftIndex],
            let nonMatchingRightIndex = (0..<model.fixedRows).first(where: {
                if let r = model.rightItems[$0] { return r.id != leftItem.id }
                return false
            })
        else {
            Issue.record("Setup for mismatch not possible.")
            return
        }
        
        // Pick another left index (different from mismatched one) that is not nil
        let anotherLeft = (0..<model.fixedRows).first(where: { $0 != leftIndex && model.roundItems[$0] != nil })
        
        model.toggleLeftSelection(leftIndex)
        model.toggleRightSelection(nonMatchingRightIndex)
        
        Task { await model.confirmSelectionIfMatching() }
        try? await Task.sleep(nanoseconds: 50_000_000) // allow state to update
        
        // The mismatched slots must be frozen
        #expect(model.isLeftFrozen(leftIndex) == true)
        #expect(model.isRightFrozen(nonMatchingRightIndex) == true)
        
        // Another left (if exists) should not be frozen
        if let anotherLeft {
            #expect(model.isLeftFrozen(anotherLeft) == false)
        }
    }
}
