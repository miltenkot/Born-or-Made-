//
//  QAItem.swift
//  BoM
//
//  Created by Bartlomiej Lanczyk on 11/11/2025.
//

import Foundation

struct QAItem: Identifiable, Hashable {
    let id = UUID()
    let question: String
    let answer: String
}
