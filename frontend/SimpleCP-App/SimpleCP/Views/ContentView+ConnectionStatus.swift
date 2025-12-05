//
//  ContentView+ConnectionStatus.swift
//  SimpleCP
//
//  Connection status indicator extension for ContentView
//

import SwiftUI

extension ContentView {
    // MARK: - Connection Status Indicator

    var connectionStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(connectionStatusColor.opacity(0.3), lineWidth: 1)
                        .scaleEffect(connectionPulseScale)
                        .animation(connectionAnimation, value: backendService.isRunning)
                )

            Text(connectionStatusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(connectionStatusBackgroundColor)
        .cornerRadius(8)
        .help(connectionTooltipText)
        .onTapGesture {
            // Allow manual restart on tap
            if !backendService.isRunning {
                backendService.restartBackend()
            }
        }
    }

    // MARK: - Connection Status Properties

    var connectionStatusColor: Color {
        if backendService.isReady {
            return .green
        } else if backendService.isRunning {
            return .yellow
        } else if backendService.isMonitoring {
            return .orange
        } else {
            return .red
        }
    }

    var connectionStatusText: String {
        if backendService.isReady {
            return "Connected"
        } else if backendService.isRunning {
            return "Starting..."
        } else if backendService.isMonitoring {
            return "Connecting..."
        } else {
            return "Offline"
        }
    }

    var connectionStatusBackgroundColor: Color {
        if backendService.isReady {
            return Color.green.opacity(0.1)
        } else if backendService.isRunning {
            return Color.yellow.opacity(0.1)
        } else if backendService.isMonitoring {
            return Color.orange.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }

    var connectionTooltipText: String {
        if backendService.isReady {
            return "Backend is connected and ready"
        } else if backendService.isRunning {
            return "Backend is starting up..."
        } else if backendService.isMonitoring {
            if backendService.restartCount > 0 {
                return "Reconnecting... (attempt \(backendService.restartCount))"
            }
            return "Connecting to backend..."
        } else {
            return "Backend is offline - tap to restart"
        }
    }

    var connectionPulseScale: CGFloat {
        (backendService.isRunning && !backendService.isReady) || (backendService.isMonitoring && !backendService.isRunning) ? 1.5 : 1.0
    }

    var connectionAnimation: Animation? {
        if (backendService.isRunning && !backendService.isReady) || (backendService.isMonitoring && !backendService.isRunning) {
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        }
        return .easeInOut(duration: 0.3)
    }
}
