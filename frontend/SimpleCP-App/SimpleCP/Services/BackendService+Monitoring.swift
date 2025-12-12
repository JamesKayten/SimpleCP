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
        #if DEBUG
        print("🏥 Health check starting on http://127.0.0.1:\(port)/health")
        #endif
        
        // First check if process is even running
        await MainActor.run {
            if let process = self.backendProcess, process.isRunning {
                #if DEBUG
                print("   Process running (PID: \(process.processIdentifier))")
                #endif
            } else {
                print("⚠️ Backend process is NOT running or is nil")
            }
        }
        
        // Retry health check up to 3 times with delays
        for attempt in 1...3 {
            #if DEBUG
            if attempt > 1 {
                print("🏥 Health check retry attempt \(attempt)/3...")
            }
            #endif
            
            do {
                // Use 127.0.0.1 consistently to avoid IPv6 resolution issues
                let url = URL(string: "http://127.0.0.1:\(port)/health")!
                var request = URLRequest(url: url)
                request.timeoutInterval = 5.0
                
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let responseText = String(data: data, encoding: .utf8) {
                            #if DEBUG
                            print("🏥 Response: \(responseText)")
                            #endif
                        }
                        await MainActor.run {
                            logger.info("Backend health check passed")
                            self.consecutiveFailures = 0
                            self.backendError = nil
                            self.isReady = true  // Backend is now ready for API calls
                            self.connectionState = .connected
                            print("✅ Backend connected and ready")
                        }
                        return // Success! Exit the retry loop
                    } else {
                        print("⚠️ Health check returned status: \(httpResponse.statusCode)")
                        if attempt < 3 {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            continue
                        }
                    }
                }
            } catch let error as URLError {
                // Only log connection refused on first attempt or last attempt
                if attempt == 1 || attempt == 3 {
                    print("⚠️ Health check attempt \(attempt): Connection not ready yet")
                }
                
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
                
                // Last attempt failed - provide diagnostics
                let diagnostic: String
                switch error.code {
                case .cannotConnectToHost:
                    diagnostic = "Cannot connect - backend may not be listening on port \(port)"
                case .timedOut:
                    diagnostic = "Connection timed out - backend is slow to respond or not running"
                case .cannotFindHost:
                    diagnostic = "Cannot find localhost - network configuration issue"
                default:
                    diagnostic = error.localizedDescription
                }
                
                print("❌ Health check failed: \(diagnostic)")
                logger.error("Backend health check failed: \(diagnostic)")
            } catch {
                if attempt == 3 {
                    print("❌ Health check failed: \(error.localizedDescription)")
                    logger.error("Backend health check failed: \(error.localizedDescription)")
                }
                
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    continue
                }
            }
        }
        
        // All attempts failed
        print("❌ All health check attempts failed")
        await MainActor.run {
            self.isReady = false
            self.connectionState = .error("Health check failed after 3 attempts")
        }
        await handleHealthCheckFailure()
    }

    func handleHealthCheckFailure() async {
        await MainActor.run {
            self.consecutiveFailures += 1
            logger.warning("Health check failure #\(self.consecutiveFailures)")

            if self.consecutiveFailures >= 3 && self.autoRestartEnabled {
                logger.error("Multiple health check failures, triggering restart")
                print("🔄 Multiple health check failures, triggering restart")
                triggerAutoRestart(reason: "Health check failures")
            }
        }
    }

    // MARK: - Process Monitoring

    func quickHealthCheck() async {
        do {
            // Use 127.0.0.1 consistently to avoid IPv6 resolution issues
            let url = URL(string: "http://127.0.0.1:\(port)/health")!
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
            logger.error("Maximum restart attempts (\(self.maxRestartAttempts)) reached")
            print("🛑 Maximum restart attempts reached. Manual intervention required:")
            print("   1. Check Console.app for backend errors")
            print("   2. Run: lsof -ti:\(port) | xargs kill -9")
            print("   3. Manually restart from Settings")
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
                print("⏳ Waiting \(String(format: "%.1f", waitTime))s before restart attempt")

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
}
