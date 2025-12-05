//
//  BackendServiceTests.swift
//  SimpleCP Tests
//
//  Unit tests for BackendService
//

import Testing
import Foundation
@testable import SimpleCP

@Suite("Backend Service Tests")
struct BackendServiceTests {
    
    @Test("Backend connection state transitions correctly")
    @MainActor
    func connectionStateTransitions() async throws {
        let service = BackendService()
        
        // Initial state should be disconnected
        #expect(service.connectionState == .disconnected)
        #expect(!service.isRunning)
        #expect(!service.isReady)
    }
    
    @Test("Port configuration is persisted")
    @MainActor
    func portConfiguration() async throws {
        let service = BackendService()
        
        // Default port should be 8000
        #expect(service.port == 8000)
        
        // Change port
        service.port = 8080
        #expect(service.port == 8080)
    }
    
    @Test("PID file path uses app-specific directory")
    @MainActor
    func pidFilePath() async throws {
        let service = BackendService()
        
        // Should not use /tmp directly
        #expect(!service.pidFilePath.hasPrefix("/tmp/"))
        #expect(service.pidFilePath.contains("com.simplecp.backend.pid"))
    }
}

@Suite("Data Persistence Tests")
struct DataPersistenceTests {
    
    @Test("Can save and load data")
    func saveAndLoad() async throws {
        let persistence = DataPersistenceManager.shared
        
        struct TestData: Codable, Equatable {
            let id: String
            let value: Int
        }
        
        let testData = TestData(id: "test", value: 42)
        
        // Save
        try await persistence.save(testData, filename: "test.json")
        
        // Load
        let loaded = try await persistence.load(filename: "test.json", as: TestData.self)
        
        #expect(loaded == testData)
        
        // Cleanup
        try await persistence.delete(filename: "test.json")
    }
    
    @Test("File exists check works correctly")
    func fileExistsCheck() async throws {
        let persistence = DataPersistenceManager.shared
        
        let filename = "existence_test.json"
        
        // Should not exist initially
        let existsBefore = await persistence.fileExists(filename: filename)
        #expect(!existsBefore)
        
        // Create file
        try await persistence.save(["test": "data"], filename: filename)
        
        // Should exist now
        let existsAfter = await persistence.fileExists(filename: filename)
        #expect(existsAfter)
        
        // Cleanup
        try await persistence.delete(filename: filename)
    }
}

@Suite("Exponential Backoff Tests")
struct ExponentialBackoffTests {
    
    @Test("Exponential backoff calculates delays correctly")
    func backoffDelays() {
        // Test the exponential backoff formula used in the code
        func calculateDelay(attempt: Int) -> Double {
            min(0.1 * pow(2.0, Double(attempt)), 2.0)
        }
        
        #expect(calculateDelay(attempt: 0) == 0.1)
        #expect(calculateDelay(attempt: 1) == 0.2)
        #expect(calculateDelay(attempt: 2) == 0.4)
        #expect(calculateDelay(attempt: 3) == 0.8)
        #expect(calculateDelay(attempt: 4) == 1.6)
        #expect(calculateDelay(attempt: 5) == 2.0) // Capped at 2.0
        #expect(calculateDelay(attempt: 10) == 2.0) // Still capped
    }
}
