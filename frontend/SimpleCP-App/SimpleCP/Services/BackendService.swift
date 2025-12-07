//
//  BackendService.swift
//  SimpleCP
//
//  Manages the Python backend process lifecycle
//

import Foundation
import os.log
import SwiftUI

struct BackendStartupConfig {
    let projectRoot: URL
    let backendPath: URL
    let mainPyPath: URL
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
    @Published var isReady: Bool = false  // Tracks if backend is ready for API calls
    @Published var connectionState: BackendConnectionState = .disconnected
    @Published var backendError: String?
    @Published var restartCount: Int = 0
    @Published var isMonitoring: Bool = false
    
    // Port 49917 derived from "SimpleCP" hash (private port range 49152-65535)
    @AppStorage("backendPort") var port: Int = 49917

    var backendProcess: Process?
    let logger = Logger(subsystem: "com.simplecp.app", category: "backend")
    
    // Use app-specific temporary directory instead of /tmp
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
        startMonitoring()

        // Auto-start backend on initialization with proper state management
        Task { @MainActor in
            await startBackendWithExponentialBackoff()
        }
    }
    
    // MARK: - Exponential Backoff Startup
    
    /// Starts backend with exponential backoff retry logic
    func startBackendWithExponentialBackoff() async {
        for attempt in 0..<5 {
            let delay = min(0.1 * pow(2.0, Double(attempt)), 2.0) // Max 2 seconds
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if !isRunning {
                startBackend()
                
                // Wait to verify startup
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                if isRunning {
                    logger.info("✅ Backend started successfully on attempt \(attempt + 1)")
                    return
                }
            } else {
                return
            }
        }
        
        logger.error("❌ Failed to start backend after 5 attempts")
        connectionState = .error("Failed to start after multiple attempts")
    }

    // MARK: - Port Management

    func isPortInUse(_ port: Int) -> Bool {
        let task = Process()
        task.launchPath = "/usr/sbin/lsof"
        task.arguments = ["-t", "-i:\(port)"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return !output.isEmpty
        } catch {
            logger.error("Failed to check port status: \(error.localizedDescription)")
            return false
        }
    }

    func killProcessOnPort(_ port: Int) -> Bool {
        logger.info("Attempting to kill process on port \(port)")

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "lsof -t -i:\(port) | xargs kill -9 2>/dev/null"]

        do {
            try task.run()
            task.waitUntilExit()

            Thread.sleep(forTimeInterval: 0.5)

            if !isPortInUse(port) {
                logger.info("Successfully freed port \(port)")
                return true
            } else {
                logger.warning("Port \(port) still in use after kill attempt")
                return false
            }
        } catch {
            logger.error("Failed to kill process on port \(port): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Backend Lifecycle

    func startBackend() {
        if isRunning, let process = backendProcess, process.isRunning {
            logger.info("Backend already running")
            return
        }
        
        connectionState = .connecting
        
        if isPortInUse(port) {
            handlePortOccupied()
            return
        }

        guard let startupConfig = validateStartupEnvironment() else {
            connectionState = .error(backendError ?? "Validation failed")
            return
        }
        
        startBackendProcess(config: startupConfig)
    }

    func handlePortOccupied() {
        logger.warning("Port \(self.port) is already in use.")
        connectionState = .connecting
        
        // Try to connect to the existing backend
        Task {
            let url = URL(string: "http://localhost:\(port)/health")!
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run {
                        logger.info("✅ Existing backend on port \(self.port) is healthy, using it")
                        isRunning = true
                        isReady = true
                        connectionState = .connected
                        backendError = nil
                        startHealthChecks()
                    }
                    return
                }
            } catch {
                logger.warning("❌ Port occupied but backend not responding, may need manual cleanup")
            }
            
            await MainActor.run {
                backendError = "Backend port \(self.port) is occupied by unresponsive process. " +
                    "Please kill the process manually: lsof -ti:\(self.port) | xargs kill -9"
                connectionState = .error("Port \(self.port) occupied")
            }
        }
    }

    func validateStartupEnvironment() -> BackendStartupConfig? {
        guard let projectRoot = findProjectRoot() else {
            backendError = "Could not find project root directory"
            logger.error("Failed to find project root")
            return nil
        }

        let backendPath = projectRoot.appendingPathComponent("backend")
        let mainPyPath = backendPath.appendingPathComponent("main.py")

        guard FileManager.default.fileExists(atPath: mainPyPath.path) else {
            backendError = "Backend not found at: \(mainPyPath.path)"
            logger.error("Backend main.py not found")
            return nil
        }

        guard let python3Path = findPython3() else {
            backendError = "Python 3 not found. Please install Python 3."
            logger.error("Python 3 not found")
            return nil
        }

        return BackendStartupConfig(
            projectRoot: projectRoot,
            backendPath: backendPath,
            mainPyPath: mainPyPath,
            python3Path: python3Path
        )
    }

    func startBackendProcess(config: BackendStartupConfig) {
        logger.info("Starting backend...")
        logger.info("   Python: \(config.python3Path)")
        logger.info("   Backend: \(config.mainPyPath.path)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: config.python3Path)
        process.arguments = [config.mainPyPath.path]
        process.currentDirectoryURL = config.backendPath

        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        process.environment = environment

        setupProcessPipes(process: process)

        process.terminationHandler = { [weak self] terminatedProcess in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Only mark as not running if this is still our current process
                if self.backendProcess === terminatedProcess {
                    self.isRunning = false
                    self.isReady = false
                    self.connectionState = .disconnected
                    self.backendProcess = nil
                    self.logger.info("Backend process terminated (exit code: \(terminatedProcess.terminationStatus))")
                } else {
                    self.logger.info("Old backend process terminated (exit code: \(terminatedProcess.terminationStatus)), but a new one is already running")
                }
                
                try? FileManager.default.removeItem(atPath: self.pidFilePath)
            }
        }

        do {
            try process.run()
            backendProcess = process

            let pid = process.processIdentifier
            try? "\(pid)".write(toFile: pidFilePath, atomically: true, encoding: .utf8)

            Thread.sleep(forTimeInterval: 1.0)

            Task {
                await verifyBackendHealth()
            }

            isRunning = true
            connectionState = .connecting // Will be updated to .connected after health check
            backendError = nil
            logger.info("Backend started successfully (PID: \(pid))")
        } catch {
            backendError = "Failed to start backend: \(error.localizedDescription)"
            connectionState = .error("Failed to start")
            logger.error("Failed to launch backend process: \(error.localizedDescription)")
        }
    }

    private func setupProcessPipes(process: Process) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                self?.logger.debug("Backend stdout: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                self?.logger.error("Backend stderr: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
    }

    func stopBackend() {
        guard let process = backendProcess, process.isRunning else {
            logger.info("Backend not running")
            isRunning = false
            isReady = false
            connectionState = .disconnected
            return
        }

        logger.info("Stopping backend...")
        isReady = false  // Backend is no longer ready
        connectionState = .disconnected
        process.terminate()

        let deadline = Date().addingTimeInterval(2.0)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.isRunning {
            logger.warning("Backend didn't stop gracefully, force killing...")
            process.interrupt()
            Thread.sleep(forTimeInterval: 0.2)

            if process.isRunning {
                let pid = process.processIdentifier
                kill(pid, SIGKILL)
                logger.warning("Sent SIGKILL to backend process")
            }
        }

        backendProcess = nil
        isRunning = false

        try? FileManager.default.removeItem(atPath: pidFilePath)

        if isPortInUse(port) {
            _ = killProcessOnPort(port)
        }

        logger.info("Backend stopped")
    }

    func restartBackend() {
        logger.info("Manually restarting backend...")
        resetRestartCounter()
        stopBackend()
        Thread.sleep(forTimeInterval: 0.5)
        startBackend()
    }

    nonisolated deinit {
        // Note: Cannot call main actor-isolated methods from deinit
        // Cleanup should be called explicitly before deallocation via stopMonitoring()
        // If process is still running, force terminate it
        if let process = backendProcess, process.isRunning {
            process.terminate()
        }
    }
    
    // MARK: - Cleanup
    
    /// Explicitly cleanup resources - call this before the service is deallocated
    func cleanup() {
        stopMonitoring()
        stopBackend()
    }
}
