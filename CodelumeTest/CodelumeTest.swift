//
//  CodelumeTest.swift
//  CodelumeTest
//
//  Created by 广子俞 on 2026/1/27.
//

import Testing
import Foundation
import Supabase
@testable import Codelume

struct CodelumeTest {
    
    @Test func testSupabaseSignUP() async throws {
        let manager = SupabaseManager.shared
        
//        let response = try await manager.client.auth.signUp(
//            email: "codelume@163.com",
//            password: "123456"
//        )
//        print("注册成功: \(response.user.id)")
        
        // print(response)
        let session = try await manager.signIn(email: "codelume@163.com", password: "123456")
        print("----------------- session -----------------")
        //        print(session)
        //        try await manager.signOut()
        //        print("----------------- signOut -----------------")
        //        print("signOut")
    }
    
}
