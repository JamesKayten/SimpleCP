//
//  StatusBarView.swift
//  SimpleCPApp
//
//  Status bar for messages and errors
//

import SwiftUI

struct StatusBarView: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(isError ? .red : .blue)

            Text(message)
                .font(.caption)
                .foregroundColor(isError ? .red : .primary)

            Spacer()
        }
        .padding(8)
        .background(isError ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
    }
}

#Preview {
    VStack {
        StatusBarView(message: "Connected to backend", isError: false)
        StatusBarView(message: "Failed to load data", isError: true)
    }
}
