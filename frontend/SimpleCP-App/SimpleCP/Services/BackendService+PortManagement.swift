//
//  BackendService+PortManagement.swift
//  SimpleCP
//
//  Port management utilities for BackendService
//

import Foundation

extension BackendService {
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

    func handlePortOccupied() {
        logger.warning("Port \(self.port) is already in use.")
        connectionState = .connecting

        // Try to connect to the existing backend - use explicit IPv4 to avoid IPv6 issues
        Task {
            let url = URL(string: "http://127.0.0.1:\(self.port)/health")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.0 // Give it a bit more time

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await MainActor.run {
                        self.logger.info("✅ Existing backend on port \(self.port) is healthy, using it")
                        self.isRunning = true
                        self.isReady = true
                        self.connectionState = .connected
                        self.backendError = nil
                        self.startHealthChecks()
                    }
                    return
                }
            } catch {
                self.logger.warning("❌ Port occupied but backend not responding: \(error.localizedDescription)")

                // Wait a moment - the backend might still be starting up
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Try ONE more time before killing
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        await MainActor.run {
                            self.logger.info("✅ Backend responded on second try - it was still starting up")
                            self.isRunning = true
                            self.isReady = true
                            self.connectionState = .connected
                            self.backendError = nil
                            self.startHealthChecks()
                        }
                        return
                    }
                } catch {
                    self.logger.warning("❌ Still not responding after retry, will kill and restart")
                }
            }

            // Port is occupied but not responding after retries - kill it and start fresh
            await MainActor.run {
                self.forceKillAndRestart()
            }
        }
    }

    /// Forcefully kill any process on the port and restart backend
    func forceKillAndRestart() {
        let portNum = self.port
        logger.info("🔪 Force killing process on port \(portNum) and restarting...")

        // Try multiple times to kill the process
        for attempt in 1...3 {
            if killProcessOnPort(portNum) {
                logger.info("✅ Port \(portNum) freed on attempt \(attempt)")

                // Wait a moment for the OS to fully release the port
                Thread.sleep(forTimeInterval: 0.3)

                // Verify it's actually free
                if !isPortInUse(portNum) {
                    logger.info("✅ Port verified free, starting backend...")
                    startBackend()
                    return
                }
            }

            logger.warning("⚠️ Kill attempt \(attempt) - port still in use, waiting...")
            Thread.sleep(forTimeInterval: 0.5)
        }

        // If we still can't free the port, report the error
        backendError = "Could not free port \(portNum) after 3 attempts"
        connectionState = .error("Port \(portNum) stuck")
        logger.error("❌ Failed to free port \(portNum) after 3 kill attempts")
    }
}
