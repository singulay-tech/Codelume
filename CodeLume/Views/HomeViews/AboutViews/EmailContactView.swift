import SwiftUI

struct EmailContactView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var isShowingMailDialog = false
    let emailAddress: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Support Email", systemImage: "envelope")
                            .font(.headline)
                        Text(emailAddress)
                            .textSelection(.enabled)
                            .foregroundColor(.accentColor)
                            .font(.body.monospaced())
                        
                        Button("Copy Email Address") {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(emailAddress, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Contact Information")
                }
                
                Section {
                    TextField("Subject", text: $emailSubject)
                        .textFieldStyle(.roundedBorder)
                    
                    TextEditor(text: $emailBody)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    HStack {
                        Text("Your message will open in your default email client.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Open in Mail") {
                            openEmailClient()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(emailSubject.isEmpty && emailBody.isEmpty)
                    }
                    .padding(.top, 8)
                } header: {
                    Text("Compose Message")
                } footer: {
                    Text("We typically respond within 1-2 business days.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .frame(width: 500, height: 450)
            .navigationTitle("Contact via Email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openEmailClient() {
        let subject = emailSubject.isEmpty ? "Codelume Inquiry" : emailSubject
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURLString = "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURLString) {
            NSWorkspace.shared.open(url)
            dismiss()
        }
    }
}


#Preview {
    EmailContactView(emailAddress: "codelume@163.com")
}
