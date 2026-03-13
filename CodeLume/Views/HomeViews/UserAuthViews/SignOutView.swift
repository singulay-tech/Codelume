import SwiftUI

struct SignOutView: View {
    @Environment(\.dismiss) private var dismiss
    private let supabase = SupabaseManager.shared
    
    var body: some View {
        VStack {
            CodelumeIcon()

            Spacer()

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
        .frame(width: 280, height: 180)
    }
}

#Preview {
    SignOutView()
}
