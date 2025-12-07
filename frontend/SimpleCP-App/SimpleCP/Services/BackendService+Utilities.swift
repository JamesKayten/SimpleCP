//
//  BackendService+Utilities.swift
//  SimpleCP
//
//  Utility functions for BackendService
//

import Foundation

extension BackendService {
    // MARK: - Project Discovery

    func findProjectRoot() -> URL? {
        // Priority 1: Hardcoded path for development (most reliable for Xcode)
        let devPath = "/Volumes/User_Smallfavor/Users/Smallfavor/Code/ACTIVE/SimpleCP"
        let devURL = URL(fileURLWithPath: devPath)
        let devBackend = devURL.appendingPathComponent("backend")
        if FileManager.default.fileExists(atPath: devBackend.path) {
            logger.info("Found project root via dev path: \(devPath)")
            return devURL
        }

        // Priority 2: Check environment variable (set by development tools)
        if let projectDir = ProcessInfo.processInfo.environment["PROJECT_DIR"],
           !projectDir.isEmpty {
            let url = URL(fileURLWithPath: projectDir)
            let backendURL = url.appendingPathComponent("backend")
            if FileManager.default.fileExists(atPath: backendURL.path) {
                logger.info("Found project root via PROJECT_DIR: \(projectDir)")
                return url
            }
        }

        // Priority 3: Check current working directory (common for swift run)
        let cwdPath = FileManager.default.currentDirectoryPath
        let cwdURL = URL(fileURLWithPath: cwdPath)
        let cwdBackend = cwdURL.appendingPathComponent("backend")
        if FileManager.default.fileExists(atPath: cwdBackend.path) {
            logger.info("Found project root via current directory: \(cwdPath)")
            return cwdURL
        }

        // Priority 4: Walk up from current directory (for swift run from subdirectory)
        var walkURL = cwdURL
        for _ in 0..<5 {
            let backendURL = walkURL.appendingPathComponent("backend")
            if FileManager.default.fileExists(atPath: backendURL.path) {
                logger.info("Found project root by walking up: \(walkURL.path)")
                return walkURL
            }
            walkURL = walkURL.deletingLastPathComponent()
        }

        // Priority 5: Start from bundle and walk up (for built app)
        var currentURL = Bundle.main.bundleURL
        for _ in 0..<10 {
            let backendURL = currentURL.appendingPathComponent("backend")
            if FileManager.default.fileExists(atPath: backendURL.path) {
                logger.info("Found project root via bundle: \(currentURL.path)")
                return currentURL
            }
            currentURL = currentURL.deletingLastPathComponent()
        }

        logger.error("Could not find project root containing 'backend' folder")
        return nil
    }

    // MARK: - Python Discovery

    func findPython3() -> String? {
        // Priority 1: Check for venv Python in project
        if let projectRoot = findProjectRoot() {
            let venvPython = projectRoot.appendingPathComponent(".venv/bin/python3")
            if FileManager.default.fileExists(atPath: venvPython.path) {
                logger.info("Found venv Python: \(venvPython.path)")
                return venvPython.path
            }
        }

        // Priority 2: System Python paths
        let possiblePaths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/opt/local/bin/python3"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Priority 3: Try using 'which' command
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["python3"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            logger.error("Failed to find python3: \(error.localizedDescription)")
        }

        return nil
    }

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
