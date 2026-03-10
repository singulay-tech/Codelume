//
//  CodelumeTest.swift
//  CodelumeTest
//
//  Created by 广子俞 on 2026/1/27.
//

import Testing
import Foundation
@testable import Codelume

struct UtilsTest {
    @Test func testAlert() async throws {
        Alert(title: "codleume", message: "nihao")
    }
}
