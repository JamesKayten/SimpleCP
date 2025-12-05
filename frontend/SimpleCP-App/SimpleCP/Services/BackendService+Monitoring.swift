//
//  BackendService+Monitoring.swift
//  SimpleCP
//
//  Health monitoring and auto-restart functionality for BackendService
//

import Foundation

extension BackendService {
    // MARK: - Health Check

    func verifyBackendHealth() async {
        do {
            let url = URL(string: "http://localhost:\(port)/health")!
            let (_, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await MainActor.run {
                    logger.info("Backend health check passed")
                    self.consecutiveFailures = 0
                    self.backendError = nil
                    self.isReady = true  // Backend is now ready for API calls
                    self.connectionState = .connected
                }
            } else {
                logger.warning("Backend health check returned unexpected response")
                await MainActor.run {
                    self.isReady = false
                    self.connectionState = .error("Unexpected response")
                }
                handleHealthCheckFailure()
            }
        } catch {
            logger.error("Backend health check failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isReady = false
                self.connectionState = .error("Health check failed")
            }
            handleHealthCheckFailure()
        }
    }

    func handleHealthCheckFailure() {
        self.consecutiveFailures += 1
        logger.warning("Health check failure #\(self.consecutiveFailures)")

        if self.consecutiveFailures >= 3 && self.autoRestartEnabled {
            logger.error("Multiple health check failures detected, triggering restart")
            triggerAutoRestart(reason: "Health check failures")
        }
    }

    // MARK: - Process Monitoring

    func startMonitoring() {
        guard monitoringTimer == nil else { return }

        logger.info("Starting backend process monitoring")
        isMonitoring = true

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBackendStatus()
            }
        }

        startHealthChecks()
    }

    func stopMonitoring() {
        logger.info("Stopping backend process monitoring")
        isMonitoring = false

        monitoringTimer?.invalidate()
        monitoringTimer = nil

        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    func startHealthChecks() {
        guard healthCheckTimer == nil else { return }

        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.verifyBackendHealth()
            }
        }
    }

    func checkBackendStatus() {
        guard let process = backendProcess else {
            if isRunning {
                logger.warning("Backend marked as running but process is nil")
                
                // Check if a backend is actually running on the port before restarting
                if isPortInUse(port) {
                    logger.info("Port \(self.port) is in use, checking if backend is healthy...")
                    Task {
                        await verifyBackendHealth()
                        await MainActor.run {
                            if self.isReady {
                                logger.info("Backend is healthy despite missing process reference, continuing...")
                                return
                            } else {
                                logger.warning("Backend on port \(self.port) is unhealthy, marking as not running")
                                self.isRunning = false
                                if self.autoRestartEnabled {
                                    self.triggerAutoRestart(reason: "Process lost")
                                }
                            }
                        }
                    }
                } else {
                    isRunning = false
                    if autoRestartEnabled {
                        triggerAutoRestart(reason: "Process lost")
                    }
                }
            }
            return
        }

        if !process.isRunning {
            logger.error("Backend process died unexpectedly (exit code: \(process.terminationStatus))")
            isRunning = false
            backendProcess = nil

            if autoRestartEnabled {
                let reason = "Process died (exit code: \(process.terminationStatus))"
                triggerAutoRestart(reason: reason)
            }
            return
        }

        Task {
            await quickHealthCheck()
        }
    }

    func quickHealthCheck() async {
        do {
            let url = URL(string: "http://localhost:\(port)/health")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                consecutiveFailures = 0
                if !isRunning {
                    isRunning = true
                    logger.info("Backend recovered and responding")
                }
            }
        } catch {
            consecutiveFailures += 1
        }
    }

    // MARK: - Auto-Restart

    func triggerAutoRestart(reason: String) {
        guard autoRestartEnabled else {
            logger.info("Auto-restart disabled, not restarting")
            return
        }

        guard restartCount < maxRestartAttempts else {
            logger.error("Maximum restart attempts (\(self.maxRestartAttempts)) reached, disabling auto-restart")
            autoRestartEnabled = false
            backendError = "Backend failed to restart after \(self.maxRestartAttempts) attempts. Please check logs."
            return
        }

        let now = Date()
        if let lastRestart = lastRestartTime {
            let timeSinceLastRestart = now.timeIntervalSince(lastRestart)
            if timeSinceLastRestart < restartDelay {
                let waitTime = restartDelay - timeSinceLastRestart
                logger.info("Waiting \(String(format: "%.1f", waitTime))s before restart attempt")

                DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
                    self.performAutoRestart(reason: reason)
                }
                return
            }
        }

        performAutoRestart(reason: reason)
    }

    func performAutoRestart(reason: String) {
        self.restartCount += 1
        self.lastRestartTime = Date()

        self.restartDelay = min(self.restartDelay * 2, 30.0)

        logger.info("Auto-restarting backend (attempt \(self.restartCount)/\(self.maxRestartAttempts)) - Reason: \(reason)")

        self.stopBackend()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startBackend()
        }
    }

    func setAutoRestartEnabled(_ enabled: Bool) {
        autoRestartEnabled = enabled
        logger.info("Auto-restart \(enabled ? "enabled" : "disabled")")
    }

    func resetRestartCounter() {
        restartCount = 0
        consecutiveFailures = 0
        restartDelay = 2.0
        lastRestartTime = nil
        autoRestartEnabled = true
        logger.info("Restart counter reset")
    }
}
