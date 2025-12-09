//
//  BackendService+Utilities.swift
//  SimpleCP
//
//  Utility functions for BackendService
//

import Foundation

extension BackendService {
    // MARK: - Dependency Installation
    
    func installDependenciesManually() async -> Bool {
        logger.info("Installing Python dependencies...")
        
        guard let projectRoot = findProjectRoot() else {
            logger.error("Cannot install dependencies: project root not found")
            return false
        }
        
        let backendPath = projectRoot.appendingPathComponent("backend")
        let requirementsPath = backendPath.appendingPathComponent("requirements.txt")
        
        guard FileManager.default.fileExists(atPath: requirementsPath.path) else {
            logger.error("Cannot install dependencies: requirements.txt not found at \(requirementsPath.path)")
            return false
        }
        
        guard let python3Path = findPython3() else {
            logger.error("Cannot install dependencies: Python 3 not found")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: python3Path)
            process.arguments = ["-m", "pip", "install", "-r", requirementsPath.path]
            process.currentDirectoryURL = backendPath
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    self.logger.info("pip install: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
            
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                    self.logger.warning("pip install error: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
            
            process.terminationHandler = { process in
                let success = process.terminationStatus == 0
                if success {
                    self.logger.info("✅ Dependencies installed successfully")
                } else {
                    self.logger.error("❌ Failed to install dependencies (exit code: \(process.terminationStatus))")
                }
                continuation.resume(returning: success)
            }
            
            do {
                try process.run()
                self.logger.info("Running: \(python3Path) -m pip install -r \(requirementsPath.path)")
            } catch {
                self.logger.error("Failed to launch pip install: \(error.localizedDescription)")
                continuation.resume(returning: false)
            }
        }
    }

    // MARK: - Cleanup

    func cleanupTimers() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    func cleanupProcess() {
        if let process = backendProcess, process.isRunning {
            process.terminate()
        }
    }
}
