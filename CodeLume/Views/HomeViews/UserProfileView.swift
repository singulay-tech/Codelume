//
//  UserProfileView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/28.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    private var supabaseM = SupabaseManager.shared
    
    @State private var userProfile: UserTable?
    @State private var isLoading = false
    @State private var showingChangePassword = false
    @State private var showingChangeAvatar = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        ZStack {
            GlowOrbs()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            AuroraView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(spacing: 30) {
                if isLoading {
                    ProgressView("Loading...")
                        .font(.headline)
                        .padding()
                } else if let profile = userProfile {
                    VStack(spacing: 30) {
                        // 用户头像
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
                            .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
                        
                        // 用户名
                        Text(profile.username)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // 邮箱
                        if let email = profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // 功能按钮
                        VStack(spacing: 16) {
                            // 修改密码按钮
                            Button {
                                showingChangePassword = true
                            } label: {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .frame(width: 24)
                                    Text("Change Password")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showingChangePassword) {
                                ChangePasswordView()
                            }
                            
                            // 修改头像按钮
                            Button {
                                showingChangeAvatar = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .frame(width: 24)
                                    Text("Change Avatar")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showingChangeAvatar) {
                                ChangeAvatarView()
                            }
                            
                            // 登出按钮
                            Button {
                                showingLogoutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill")
                                        .frame(width: 24)
                                    Text("Logout")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .alert("Logout", isPresented: $showingLogoutAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Logout", role: .destructive) {
                                    Task {
                                        try? await supabaseM.signOut()
                                        dismiss()
                                    }
                                }
                            } message: {
                                Text("Are you sure you want to logout?")
                            }
                        }
                        .frame(maxWidth: 350)
                    }
                }
            }
            .padding(40)
        }
        .frame(width: 480, height: 480)
        .onAppear {
            loadUserProfile()
        }
    }
    
    func loadUserProfile() {
        Task {
            isLoading = true
            do {
                let profile = try await supabaseM.getUserProfile()
                await MainActor.run {
                    userProfile = profile
                    isLoading = false
                }
            } catch {
                print("Failed to load user profile: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    private var supabaseM = SupabaseManager.shared
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Change Password")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                SecureField("Current Password", text: $currentPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Change Password") {
                    changePassword()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 400, height: 350)
    }
    
    func changePassword() {
        Task {
            isLoading = true
            errorMessage = ""
            successMessage = ""
            
            do {
                if newPassword != confirmPassword {
                    errorMessage = "Passwords do not match"
                    isLoading = false
                    return
                }
                
                if newPassword.count < 6 {
                    errorMessage = "Password must be at least 6 characters"
                    isLoading = false
                    return
                }
                
                try await supabaseM.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
                
                await MainActor.run {
                    successMessage = "Password changed successfully"
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to change password: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct ChangeAvatarView: View {
    @Environment(\.dismiss) private var dismiss
    private var supabaseM = SupabaseManager.shared
    
    @State private var selectedAvatar: String? = nil
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    let avatarOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.badge.plus.fill",
        "person.text.rectangle.fill",
        "person.wave.2.fill"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Change Avatar")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(avatarOptions, id: \.self) { avatar in
                    Button {
                        selectedAvatar = avatar
                    } label: {                       ZStack {
                            Circle()
                                .fill(selectedAvatar == avatar ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: avatar)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(selectedAvatar == avatar ? .accentColor : .secondary)
                                }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveAvatar()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || selectedAvatar == nil)
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 400, height: 450)
    }
    
    func saveAvatar() {
        Task {
            isLoading = true
            errorMessage = ""
            successMessage = ""
            
            do {
                if let avatar = selectedAvatar {
                    try await supabaseM.updateUserAvatar(avatarName: avatar)
                    
                    await MainActor.run {
                        successMessage = "Avatar updated successfully"
                        isLoading = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to update avatar: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
