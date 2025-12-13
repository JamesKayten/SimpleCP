//
//  BackendService+PathDiscovery.swift
//  SimpleCP
//
//  Path discovery utilities for BackendService
//

import Foundation

extension BackendService {
    // MARK: - Path Discovery

    func findProjectRoot() -> URL? {
        // Try multiple strategies to find project root

        // Strategy 1: Check bundle's resource path (for development)
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            let projectRoot = resourceURL.deletingLastPathComponent()
            let backendPath = projectRoot.appendingPathComponent("backend/daemon.py")

            if FileManager.default.fileExists(atPath: backendPath.path) {
                logger.info("Found project root via bundle resources: \(projectRoot.path)")
                return projectRoot
            }
        }

        // Strategy 2: Check current working directory
        let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let backendInCurrent = currentDir.appendingPathComponent("backend/daemon.py")

        if FileManager.default.fileExists(atPath: backendInCurrent.path) {
            logger.info("Found project root in current directory: \(currentDir.path)")
            return currentDir
        }

        // Strategy 3: Check parent directories
        var searchURL = currentDir
        for _ in 0..<5 {
            searchURL = searchURL.deletingLastPathComponent()
            let backendPath = searchURL.appendingPathComponent("backend/daemon.py")

            if FileManager.default.fileExists(atPath: backendPath.path) {
                logger.info("Found project root in parent directory: \(searchURL.path)")
                return searchURL
            }
        }

        // Strategy 4: Check common development paths
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let commonPaths = [
            "Code/ACTIVE/SimpleCP",
            "Projects/SimpleCP",
            "Developer/SimpleCP",
            "SimpleCP"
        ]

        for path in commonPaths {
            let testURL = homeDir.appendingPathComponent(path)
            let backendPath = testURL.appendingPathComponent("backend/daemon.py")

            if FileManager.default.fileExists(atPath: backendPath.path) {
                logger.info("Found project root in common path: \(testURL.path)")
                return testURL
            }
        }

        logger.error("Could not find project root - backend/daemon.py not found in any location")
        return nil
    }

    func findPython3() -> String? {
        // Priority 1: Check for virtual environment
        if let projectRoot = findProjectRoot() {
            let venvPython = projectRoot.appendingPathComponent(".venv/bin/python3")
            if FileManager.default.fileExists(atPath: venvPython.path) {
                logger.info("Found Python in venv: \(venvPython.path)")
                return venvPython.path
            }
        }

        // Priority 2: Common Python 3 locations
        let commonPaths = [
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3",
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                logger.info("Found Python at: \(path)")
                return path
            }
        }

        // Priority 3: Use 'which python3'
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["python3"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty,
               FileManager.default.fileExists(atPath: path) {
                logger.info("Found Python via 'which': \(path)")
                return path
            }
        } catch {
            logger.error("Failed to run 'which python3': \(error.localizedDescription)")
        }

        logger.error("❌ Python 3 not found")
        return nil
    }
}
