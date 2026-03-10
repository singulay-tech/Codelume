//
//  LoginView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appleSignInNonce: String?
    private let supabase = SupabaseManager.shared
    
    var body: some View {
        VStack(alignment:.center, spacing: 12) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
                .padding(.top, 16)
            
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                appleSignInNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                handleAppleSignInResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(width: 200, height: 32)
            .disabled(supabase.isLoading)
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            Text("Use your Apple account to sign in")
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(width: 350, height: 230)
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                Alert(title: "Apple login failed!", message: "Invalid Apple credential.")
                return
            }
            
            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                Alert(title: "Apple login failed!", message: "Unable to read Apple identity token.")
                return
            }
            
            Task {
                let ret = await supabase.signInWithApple(idToken: idToken, nonce: appleSignInNonce)
                if ret {
                    dismiss()
                }
            }
            
        case .failure(let error):
            Alert(title: "Apple login failed!", message: error.localizedDescription)
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randomBytes: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            
            randomBytes.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LoginView()
}
