//
//  UserAuthView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/27.
//

import SwiftUI

struct UserAuthView: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showLoginView = false
    @State private var showLogoutView = false
    
    private var authDisplayText: LocalizedStringKey {
        if supabase.isLoading {
            return "Authenticating..."
        } else {
            if supabase.isAuthenticated {
                return LocalizedStringKey(supabase.currentUser?.email ?? "Unknown")
            } else {
                return "Log in"
            }
        }
    }
    
    var body: some View {
        HStack {
            Button {
                if !supabase.isLoading {
                    if supabase.isAuthenticated {
                        showLogoutView = true
                    } else {
                        showLoginView = true
                    }
                }
            } label: {
                Circle()
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 38, height: 38)
                    .overlay {
                        if supabase.isAuthenticated {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 28, height: 28)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                    .padding(.leading, 20)
            }
            .buttonStyle(PlainButtonStyle())
            Text(authDisplayText)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.vertical, 5)
            Spacer()
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
        }
        .sheet(isPresented: $showLogoutView) {
            LogoutView()
        }
    }
}

#Preview {
    UserAuthView()
}
