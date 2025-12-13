//
//  BackendService+Lifecycle.swift
//  SimpleCP
//
//  Backend process lifecycle management for BackendService
//

import Foundation

extension BackendService {
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

    func validateStartupEnvironment() -> BackendStartupConfig? {
        guard let projectRoot = findProjectRoot() else {
            backendError = "Could not find project root directory"
            logger.error("Failed to find project root")
            return nil
        }

        let backendPath = projectRoot.appendingPathComponent("backend")
        let daemonPyPath = backendPath.appendingPathComponent("daemon.py")

        guard FileManager.default.fileExists(atPath: daemonPyPath.path) else {
            backendError = "Backend not found at: \(daemonPyPath.path)"
            logger.error("Backend daemon.py not found")
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
            daemonPyPath: daemonPyPath,
            python3Path: python3Path
        )
    }

    func startBackendProcess(config: BackendStartupConfig) {
        logger.info("Starting backend...")
        logger.info("   Python: \(config.python3Path)")
        logger.info("   Backend: \(config.daemonPyPath.path)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: config.python3Path)
        process.arguments = [config.daemonPyPath.path, "--api-only", "--port", "\(port)"]
        process.currentDirectoryURL = config.backendPath

        var environment = ProcessInfo.processInfo.environment
        environment["PYTHONUNBUFFERED"] = "1"
        environment["SIMPLECP_PORT"] = "\(port)"  // Pass port via environment variable
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

            // Reduced initial sleep - exponential backoff handles proper waiting
            Thread.sleep(forTimeInterval: 0.5)

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

    func setupProcessPipes(process: Process) {
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
}
