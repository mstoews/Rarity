import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore
    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    enum Mode { case login, register }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Wordmark
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(Theme.brand)
                        Text("Rarity")
                            .font(.system(size: 36, weight: .heavy, design: .default))
                            .foregroundStyle(Theme.ink)
                        Text("Discover specialty beauty")
                            .font(.subheadline)
                            .foregroundStyle(Theme.sub)
                    }
                    .padding(.top, 52)

                    Picker("", selection: $mode) {
                        Text("Sign In").tag(Mode.login)
                        Text("Create Account").tag(Mode.register)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Metrics.page)

                    VStack(spacing: 12) {
                        if mode == .register {
                            RarityTextField("Username", text: $username)
                        }
                        RarityTextField("Email", text: $email, contentType: .emailAddress)
                            .textInputAutocapitalization(.never)
                        SecureField("Password", text: $password)
                            .textFieldStyle(RarityFieldStyle())
                    }
                    .padding(.horizontal, Metrics.page)

                    if let err = session.authError {
                        Text(err).font(.footnote).foregroundStyle(Theme.systemRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Metrics.page)
                    }

                    Button {
                        Task {
                            if mode == .login {
                                await session.login(email: email, password: password)
                            } else {
                                await session.register(email: email, password: password, username: username)
                            }
                        }
                    } label: {
                        Group {
                            if session.isWorking { ProgressView().tint(.white) }
                            else { Text(mode == .login ? "Sign In" : "Create Account").fontWeight(.semibold) }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent).tint(Theme.brand)
                    .disabled(session.isWorking)
                    .padding(.horizontal, Metrics.page)

                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(Theme.separator)
                        Text("or").font(.footnote).foregroundStyle(Theme.hint)
                        Rectangle().frame(height: 1).foregroundStyle(Theme.separator)
                    }
                    .padding(.horizontal, Metrics.page)

                    SignInWithAppleButton(.signIn) { req in
                        req.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleApple(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal, Metrics.page)

                    Spacer(minLength: 32)
                }
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }
            Task { await session.signInWithApple(identityToken: token, email: cred.email) }
        case .failure(let e):
            session.authError = e.localizedDescription
        }
    }
}

@ViewBuilder
private func RarityTextField(_ placeholder: String, text: Binding<String>,
                              contentType: UITextContentType? = nil) -> some View {
    TextField(placeholder, text: text)
        .textFieldStyle(RarityFieldStyle())
        .textContentType(contentType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
}

struct RarityFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(14)
            .background(Theme.card)
            .cornerRadius(Metrics.radiusRow)
            .overlay(RoundedRectangle(cornerRadius: Metrics.radiusRow).stroke(Theme.separator))
    }
}
