import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Story Tracker runs as a Safari extension. After installing this app on your iPhone, enable it under Settings → Safari → Extensions.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Enable in Safari")
                }

                Section {
                    Link("Personal OS", destination: URL(string: "https://personal-os-fe.fashandcurious.com")!)
                    Link("Safari extension help", destination: URL(string: "https://support.apple.com/guide/iphone/use-extensions-in-safari-iphab0432bf6/ios")!)
                } header: {
                    Text("Links")
                }

                Section {
                    Text("Rebuild the web extension with npm run build:safari && npm run sync:safari-ios, then run this target again from Xcode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Developers")
                }
            }
            .navigationTitle("Story Tracker")
        }
    }
}

#Preview {
    ContentView()
}
