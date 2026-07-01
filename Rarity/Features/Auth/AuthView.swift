import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                // Logo circle
                Circle()
                    .strokeBorder(Theme.separator, lineWidth: 1)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(Theme.brand)
                    )

                Text("Rarity")
                    .font(.cormorant(size: 52))
                    .foregroundStyle(Theme.ink)
                    .kerning(1)

                Text("Discover specialty beauty")
                    .font(.jost(.light, size: 15))
                    .tracking(1)
                    .foregroundStyle(Theme.sub)
            }

            Spacer()

            VStack(spacing: 14) {
                if let err = session.authError {
                    Text(err)
                        .font(.atelierCaption)
                        .foregroundStyle(Theme.destructive)
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

                #if targetEnvironment(simulator)
                Button("Dev Sign In (Simulator)") {
                    Task { await session.signInWithApple(
                        identityToken: "simulator-dev-token",
                        email: "dev@simulator.local"
                    ) }
                }
                .font(.atelierCaption)
                .foregroundStyle(Theme.hint)
                .disabled(session.isWorking)
                #endif

                if session.isWorking {
                    ProgressView().tint(Theme.brand)
                }
            }
            .padding(.bottom, 52)
        }
        .background(
            LinearGradient(
                colors: [Theme.page, Theme.brandSoft.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                session.authError = "Apple did not return credentials. Please try again."
                return
            }
            Task { await session.signInWithApple(identityToken: token, email: cred.email) }
        case .failure(let e):
            let nsErr = e as NSError
            let isCanceled = nsErr.domain == ASAuthorizationError.errorDomain
                          && nsErr.code == ASAuthorizationError.canceled.rawValue
            if !isCanceled { session.authError = e.localizedDescription }
        }
    }
}
