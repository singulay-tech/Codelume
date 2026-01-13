import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
                    NavigationLink(destination: ScreenManagerView()
                        .navigationTitle("")) {
                            Label("ScreenManager", systemImage: "display.2")
                        }
                    NavigationLink(destination: LocalWallpapersView()
                        .navigationTitle("")) {
                            Label("LocalWallpaper", systemImage: "photo.on.rectangle")
                        }
                    NavigationLink(destination: ScreenSaverView()
                        .navigationTitle("")) {
                            Label("Screen Saver", systemImage: "sparkles")
                        }
                    NavigationLink(destination: SettingsView()
                        .navigationTitle("")) {
                            Label("Preferences", systemImage: "gear")
                        }
                    NavigationLink(destination: AboutView()
                        .navigationTitle("")) {
                            Label("About", systemImage: "info.circle")
                        }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 220)
                
                Spacer()
                
                //                // MARK: - 登陆状态展示，以及登陆按钮
                //                HStack(spacing: 10) {
                //                    Button(action: {
                //                        // 这里添加打开登录界面的逻辑
                //                        // 例如：showLoginSheet = true
                //                        print("打开登录界面")
                //                    }) {
                //                        Circle()
                //                            .frame(width: 30, height: 30)
                //                            .overlay(
                //                                Image(systemName: "person.crop.circle.fill")
                //                                    .foregroundColor(.white)
                //                                    .font(.headline)
                //                            )
                //                    }
                //                    .buttonStyle(.plain)
                //
                //                    Text("未登录")
                //                        .font(.subheadline)
                //                        .foregroundColor(.secondary)
                //                }
                //                .padding(15)
                //                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(5)
                }
            }
        } detail: {
            LocalWallpapersView()
                .navigationTitle("")
        }
        .frame(minWidth: 1050, minHeight: 600)
    }
}

// MARK: - 登陆界面
struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            Text("Login")
                .font(.title)
                .padding()
            
            // 用户名输入框
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 密码输入框
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button(action: {
                    print("Sign Up按钮点击")
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                Button(action: {
                    // 这里添加登录逻辑
                    print("登录按钮点击")
                }) {
                    Text("Login")
                        .font(.headline)
                    //                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    //                        .background()
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
    }
}

// MARK: - 注册界面
struct SignUpView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.title)
                .padding()
            
            // 用户名输入框
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 邮箱输入框
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 密码输入框
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button(action: {
                    Task {
                        //                        do {
                        //                            let session = try await SupabaseManager.shared.signUp(email: email, password: password, username: username)
                        //                            Logger.info("User signed up successfully with email: \(email) and username: \(username)")
                        //                        } catch {
                        //                            Logger.error("Sign Up failed: \(error.localizedDescription)")
                        //                        }
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    HomeView()
    //    LoginView()
    //        .frame(width: 400, height: 280)
    //    SignUpView()
    //        .frame(width: 400, height: 280)
}
