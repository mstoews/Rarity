import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Theme.brand)
                Text("Rarity")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                Text("Discover specialty beauty")
                    .font(.subheadline)
                    .foregroundStyle(Theme.sub)
            }

            Spacer()

            VStack(spacing: 14) {
                if let err = session.authError {
                    Text(err).font(.footnote).foregroundStyle(Theme.systemRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Metrics.page)
                }

                SignInWithAppleButton(.signIn) { req in
                    req.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .padding(.horizontal, Metrics.page)
                .disabled(session.isWorking)

                if session.isWorking {
                    ProgressView().tint(Theme.brand)
                }
            }
            .padding(.bottom, 48)
        }
        .background(Theme.page.ignoresSafeArea())
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else { return }
            Task { await session.signInWithApple(identityToken: token, email: cred.email) }
        case .failure(let e):
            if (e as NSError).code != ASAuthorizationError.canceled.rawValue {
                session.authError = e.localizedDescription
            }
        }
    }
}
