//
//  LogoutView.swift
//  Codelume
//
//  Created by 广子俞 on 2026/1/28.
//

import SwiftUI

struct LogoutView: View {
    @Environment(\.dismiss) private var dismiss
    private let supabase = SupabaseManager.shared
    
    var body: some View {
        VStack(alignment:.center, spacing: 12) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .primary.opacity(0.1), radius: 4, y: 2)
                .padding(.top, 16)

            Text("Sign out")
                .font(.headline)

            Text("Are you sure you want to sign out?")
                .foregroundColor(.secondary)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Sign Out", role: .destructive) {
                    supabase.signOut()
                }
                .buttonStyle(.borderedProminent)
                .disabled(supabase.isLoading)
            }

            if supabase.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            Spacer()
        }
        .onChange(of: supabase.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                dismiss()
            }
        }
        .frame(width: 350, height: 230)
    }
}

#Preview {
    LogoutView()
}
