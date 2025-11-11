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
    
    private let qaItems: [QAItem] = [
        QAItem(question: "Stolica Francji", answer: "Paryż"),
        QAItem(question: "2 + 2", answer: "4"),
        QAItem(question: "Kolor nieba", answer: "Niebieski"),
        QAItem(question: "Język projektu", answer: "Swift"),
        QAItem(question: "Rok przestępny", answer: "366 dni")
    ]
    
    private var rowsCount: Int { qaItems.count }
    private var leftItems: [QAItem] { qaItems }
    
    @State private var rightItems: [QAItem] = []
    @State private var selectedLeftIndex: Int? = nil
    @State private var selectedRightIndex: Int? = nil
    
    private var isCurrentSelectionMatching: Bool {
        guard
            let li = selectedLeftIndex,
            let ri = selectedRightIndex,
            leftItems.indices.contains(li),
            rightItems.indices.contains(ri)
        else { return false }
        return leftItems[li].answer == rightItems[ri].answer
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
                    let leftTitle = leftItems[row].question
                    let isLeftSelected = (selectedLeftIndex == row)
                    let leftSelectionColor: Color = (isLeftSelected && isCurrentSelectionMatching) ? .green : .blue
                    
                    CardView(title: leftTitle, isSelected: isLeftSelected, selectionColor: leftSelectionColor)
                        .frame(height: rowHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLeftIndex = (selectedLeftIndex == row) ? nil : row
                        }
                        .accessibilityAddTraits(isLeftSelected ? .isSelected : [])
                        .accessibilityHint(Text("Left"))
                    
                    let rightTitle = rightItems.indices.contains(row) ? rightItems[row].answer : ""
                    let isRightSelected = (selectedRightIndex == row)
                    let rightSelectionColor: Color = (isRightSelected && isCurrentSelectionMatching) ? .green : .blue
                    
                    CardView(title: rightTitle, isSelected: isRightSelected, selectionColor: rightSelectionColor)
                        .frame(height: rowHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRightIndex = (selectedRightIndex == row) ? nil : row
                        }
                        .accessibilityAddTraits(isRightSelected ? .isSelected : [])
                        .accessibilityHint(Text("Right"))
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
        }
        .onAppear {
            rightItems = qaItems.shuffled()
        }
        .ignoresSafeArea(.keyboard)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Shuffle") {
                    rightItems = qaItems.shuffled()
                    selectedRightIndex = nil
                }
            }
        }
    }
}

#Preview {
    GameView()
}

