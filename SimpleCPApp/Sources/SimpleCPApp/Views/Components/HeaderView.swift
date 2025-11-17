//
//  HeaderView.swift
//  SimpleCPApp
//
//  Window header with title and actions
//

import SwiftUI

struct HeaderView: View {
    let onSaveSnippet: () -> Void

    var body: some View {
        HStack {
            Text("📋 SimpleCP")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: onSaveSnippet) {
                Image(systemName: "square.and.arrow.down")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .help("Save as Snippet")

            Button(action: {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }) {
                Image(systemName: "gearshape")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    HeaderView(onSaveSnippet: {})
        .frame(width: 600)
}
