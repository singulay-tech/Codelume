//
//  RegisterView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var passwordStrength: PasswordStrength = .weak
    @StateObject private var supabase = SupabaseManager.shared
    
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
    
    var body: some View {
        ZStack {
            GlowOrbs()
            AuroraView()
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    Text("Register")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("4-20 chars", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 250)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("example@email.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 250)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            if isPasswordVisible {
                                TextField("6+ chars", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: password) {
                                        passwordStrength = validatePassword(password)
                                    }
                                    .frame(width: 218)
                            } else {
                                SecureField("6+ chars", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: password) {
                                        passwordStrength = validatePassword(password)
                                    }
                                    .frame(width: 218)
                            }
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 25)
                        }
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(passwordStrength != .weak ? getPasswordStrengthColor(.weak) : Color.gray.opacity(0.3))
                                .frame(height: 4)
                            Rectangle()
                                .fill([.medium, .strong].contains(passwordStrength) ? getPasswordStrengthColor(.medium) : Color.gray.opacity(0.3))
                                .frame(height: 4)
                            Rectangle()
                                .fill(passwordStrength == .strong ? getPasswordStrengthColor(.strong) : Color.gray.opacity(0.3))
                                .frame(height: 4)
                        }
                        .frame(width: 218)
                        .cornerRadius(2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("Please confirm your password", text: $confirmPassword)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    SecureField("Please confirm your password", text: $confirmPassword)
                                        .textFieldStyle(.roundedBorder)
                                }
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 25)
                            }
                            .frame(width: 250)
                        }
                        
                        HStack(spacing: 16) {
                            Spacer()
                            Button("Cancel") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Register") {
                                Task {
                                    let ret =  await supabase.signUp(username: username, email: email, password: password)
                                    if ret {
                                        await MainActor.run {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 24)
                        .frame(width: 250)
                        
                        
                    }
                }
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    Button("Login now") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(10)
                .frame(width: 480)
            }
        }
        .frame(width: 480, height: 360)
    }
}

#Preview {
    RegisterView()
}
