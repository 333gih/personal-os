import SwiftUI

/// Full-height hosted frontend screen (settings, entertainment, entity detail).
struct LegacyWebTabView: View {
    let path: String

    var body: some View {
        WebAppView(startURL: PersonalOSAppConfig.frontendPath(path))
            .background(POSTheme.background)
    }
}

struct LegacyWebScreen: View {
    let route: WebSheetRoute
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            WebAppView(startURL: route.url)
                .navigationTitle(route.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { onClose() }
                            .fontWeight(.semibold)
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}
