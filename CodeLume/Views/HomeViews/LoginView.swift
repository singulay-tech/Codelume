//
//  LoginView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRegisterView = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var passwordStrength: PasswordStrength = .weak
    private let supabase = SupabaseManager.shared
    
    var body: some View {
        ZStack {
            GlowOrbs()
            AuroraView()
            VStack(alignment:.center, spacing: 12) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
                    .padding(.top, 32)
                
                HStack(alignment: .top,spacing: 20) {
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.secondary)
                        }
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                        }
                        .frame(width: 200)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: password) {
                                            passwordStrength = validatePassword(password)
                                        }
                                } else {
                                    SecureField("Password", text: $password)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: password) {
                                            passwordStrength = validatePassword(password)
                                        }
                                }
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                        .frame(width: 6)
                                }
                            }
                            .frame(width: 200)
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(passwordStrength != .weak ? getPasswordStrengthColor(.weak) : Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 4)
                                Rectangle()
                                    .fill([.medium, .strong].contains(passwordStrength) ? getPasswordStrengthColor(.medium) : Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 4)
                                Rectangle()
                                    .fill(passwordStrength == .strong ? getPasswordStrengthColor(.strong) : Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 4)
                                Spacer()
                                
                            }
                            .frame(width: 138)
                            .cornerRadius(2)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 16) {
                                Spacer()
                                Button("Cancel") {
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                                Button("Login") {
                                    login()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 23)
                            .frame(width: 200)
                        }
                    }
                }
                .frame(width: 250)
                Spacer()
                HStack {
                    Text("Don't have an account yet?")
                        .foregroundColor(.secondary)
                    Button("Register now") {
                        showRegisterView = true
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.bottom, 18)
            }
        }
        .frame(width: 480, height: 360)
        .sheet(isPresented: $showRegisterView) {
            RegisterView()
        }
    }

    private func login() {
        Task {
            let ret = await supabase.signIn(email: username, password: password)
            if ret {
                dismiss()
            }
        }
    }
    
    func validatePassword(_ password: String) -> PasswordStrength {
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let lengthValid = password.count >= 6
        
        if lengthValid && hasLetter && hasNumber {
            return password.count >= 8 ? .strong : .medium
        } else {
            return .weak
        }
    }
    
    func getPasswordStrengthColor(_ strength: PasswordStrength) -> Color {
        switch strength {
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        }
    }
}

#Preview {
    LoginView()
}
