import SwiftUI

struct AuthContainerView: View {
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
                    .navigationBarBackButtonHidden()
            } else {
                SignInView(showSignUp: $showSignUp)
                    .navigationBarBackButtonHidden()
            }
        }
    }
}
