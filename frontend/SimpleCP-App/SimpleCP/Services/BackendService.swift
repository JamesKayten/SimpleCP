//
//  BackendService.swift
//  SimpleCP
//
//  Manages the Python backend process lifecycle.
//  Extensions: +Lifecycle, +Monitoring, +PathDiscovery, +PortManagement, +Utilities
//

import Foundation
import os.log
import SwiftUI

struct BackendStartupConfig {
    let projectRoot: URL
    let backendPath: URL
    let daemonPyPath: URL
    let python3Path: String
}

enum BackendConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
}

@MainActor
class BackendService: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isReady: Bool = false
    @Published var connectionState: BackendConnectionState = .disconnected
    @Published var backendError: String?
    @Published var restartCount: Int = 0
    @Published var isMonitoring: Bool = false
    @Published var dependenciesVerified: Bool = false

    // Port 49917 derived from "SimpleCP" hash (private port range 49152-65535)
    @AppStorage("apiPort") var port: Int = 49917

    var backendProcess: Process?
    let logger = Logger(subsystem: "com.simplecp.app", category: "backend")

    var pidFilePath: String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("com.simplecp.backend.pid")
            .path
    }

    // Monitoring and auto-restart configuration
    var monitoringTimer: Timer?
    var autoRestartEnabled: Bool = true
    var maxRestartAttempts: Int = 5
    var restartDelay: TimeInterval = 2.0
    var lastRestartTime: Date?
    var consecutiveFailures: Int = 0

    // Health check configuration
    var healthCheckInterval: TimeInterval = 30.0
    var healthCheckTimer: Timer?

    init() {
        logger.info("BackendService initialized with monitoring capabilities")
        logger.info("Using port: \(self.port)")
        startMonitoring()

        Task { @MainActor in
            await self.startBackendWithExponentialBackoff()
        }
    }

    // MARK: - Exponential Backoff Startup

    func startBackendWithExponentialBackoff() async {
        if !isRunning {
            startBackend()
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            if isRunning || connectionState == .connecting || connectionState == .connected {
                logger.info("✅ Backend startup initiated on first attempt")
                await MainActor.run { self.dependenciesVerified = true }
                return
            }
        } else {
            await MainActor.run { self.dependenciesVerified = true }
            return
        }

        for attempt in 1..<3 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !isRunning && connectionState != .connecting {
                logger.info("Retry attempt \(attempt + 1)...")
                startBackend()
                try? await Task.sleep(nanoseconds: 2_000_000_000)

                if isRunning || connectionState == .connecting || connectionState == .connected {
                    logger.info("✅ Backend started on attempt \(attempt + 1)")
                    await MainActor.run { self.dependenciesVerified = true }
                    return
                }
            } else {
                await MainActor.run { self.dependenciesVerified = true }
                return
            }
        }

        logger.error("❌ Failed to start backend after 3 attempts")
        connectionState = .error("Failed to start after multiple attempts")
    }

    // MARK: - Monitoring & Health Checks

    func startMonitoring() {
        guard !isMonitoring else {
            logger.info("Monitoring already active")
            return
        }
        isMonitoring = true
        logger.info("Starting backend monitoring")
        startHealthChecks()
    }

    func stopMonitoring() {
        logger.info("Stopping backend monitoring")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    func startHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: self.healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performHealthCheck()
            }
        }
        logger.info("Health checks started (interval: \(self.healthCheckInterval)s)")
    }

    func performHealthCheck() async {
        guard isRunning else {
            logger.debug("Skipping health check - backend not running")
            return
        }
        let url = URL(string: "http://127.0.0.1:\(port)/health")!
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if !isReady {
                    logger.info("✅ Backend health check passed - marking as ready")
                    await MainActor.run {
                        self.isReady = true
                        self.connectionState = .connected
                        self.consecutiveFailures = 0
                    }
                }
            } else {
                await MainActor.run { self.handleHealthCheckFailureInternal() }
            }
        } catch {
            await MainActor.run { self.handleHealthCheckFailureInternal() }
        }
    }

    private func handleHealthCheckFailureInternal() {
        self.consecutiveFailures += 1
        logger.warning("❌ Health check failed (consecutive: \(self.consecutiveFailures))")

        if self.consecutiveFailures >= 3 {
            logger.error("Backend appears unhealthy after \(self.consecutiveFailures) failed checks")
            isReady = false
            connectionState = .error("Backend not responding")
            if autoRestartEnabled { attemptAutoRestart() }
        }
    }

    private func attemptAutoRestart() {
        if self.restartCount >= self.maxRestartAttempts {
            logger.error("❌ Max restart attempts (\(self.maxRestartAttempts)) exceeded")
            connectionState = .error("Max restarts exceeded")
            return
        }
        if let lastRestart = self.lastRestartTime, Date().timeIntervalSince(lastRestart) < 10.0 {
            logger.warning("⚠️ Skipping restart - too soon after last restart")
            return
        }
        logger.info("🔄 Attempting auto-restart (attempt \(self.restartCount + 1)/\(self.maxRestartAttempts))")
        self.lastRestartTime = Date()
        self.restartCount += 1
        Task { @MainActor in
            self.stopBackend()
            try? await Task.sleep(nanoseconds: UInt64(self.restartDelay * 1_000_000_000))
            self.startBackend()
        }
    }

    func resetRestartCounter() {
        restartCount = 0
        consecutiveFailures = 0
        restartDelay = 2.0
        lastRestartTime = nil
        autoRestartEnabled = true
        logger.info("Restart counter reset")
    }

    // MARK: - Cleanup

    func cleanup() {
        stopMonitoring()
        stopBackend()
    }

    nonisolated deinit {
        if let process = backendProcess, process.isRunning {
            process.terminate()
        }
    }
}
