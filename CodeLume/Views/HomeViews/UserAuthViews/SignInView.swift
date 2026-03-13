import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appleSignInNonce: String?
    private let supabase = SupabaseManager.shared
    
    var body: some View {
        VStack {
            CodelumeIcon()
            Spacer()
            HStack {
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    appleSignInNonce = nonce
                    request.requestedScopes = [.email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleSignInResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(width: 160, height: 32)
                .disabled(supabase.isLoading)
                
                Button("Cancel") {
                    dismiss()
                }
            }
            
            Text("Use your Apple account to sign in")
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .frame(width: 280, height: 180)
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                Alert(title: "Apple ID sign in failed!", message: "Invalid Apple credential.")
                return
            }
            
            guard let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                Alert(title: "Apple ID sign in failed!", message: "Unable to read Apple identity token.")
                return
            }
            
            Task {
                let ret = await supabase.signInWithApple(idToken: idToken, nonce: appleSignInNonce)
                if ret {
                    dismiss()
                }
            }
            
        case .failure(let error):
            Alert(title: "Apple ID sign in failed!", dynamicMessage: error.localizedDescription)
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
    SignInView()
}
