import SwiftUI

struct ComingSoonView: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: symbol)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Theme.accent)
                    Text(L("soon.title")).font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    Text(message)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
