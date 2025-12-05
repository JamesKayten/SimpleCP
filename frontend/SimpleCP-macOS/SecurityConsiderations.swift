//
//  SecurityConsiderations.swift
//  SimpleCP
//
//  Security utilities and considerations for clipboard management
//

import Foundation
import CryptoKit
import os.log

/// Handles security-related functionality for clipboard management
class SecurityManager {
    static let shared = SecurityManager()
    private let logger = Logger(subsystem: "com.simplecp.app", category: "security")
    
    // MARK: - Sensitive Content Detection
    
    /// Patterns that might indicate sensitive content
    private let sensitivePatterns = [
        // Password-like patterns
        "password:", "passwd:", "pwd:",
        // API keys
        "api_key", "apikey", "api-key",
        // Authentication tokens
        "bearer ", "token:",
        // Credit card patterns (basic)
        "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b",
        // Social Security Number pattern
        "\\b\\d{3}-\\d{2}-\\d{4}\\b",
        // Private key headers
        "-----BEGIN PRIVATE KEY-----",
        "-----BEGIN RSA PRIVATE KEY-----",
    ]
    
    /// Check if content might contain sensitive information
    func isSensitiveContent(_ content: String) -> Bool {
        let lowercased = content.lowercased()
        
        // Check for exact matches (case insensitive)
        for pattern in sensitivePatterns {
            if pattern.contains("\\b") {
                // Regex pattern
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let range = NSRange(content.startIndex..., in: content)
                    if regex.firstMatch(in: content, options: [], range: range) != nil {
                        logger.info("🔒 Detected sensitive content (pattern match)")
                        return true
                    }
                }
            } else {
                // Simple string match
                if lowercased.contains(pattern) {
                    logger.info("🔒 Detected sensitive content (keyword match)")
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Content Sanitization
    
    /// Sanitize content by redacting sensitive portions
    func sanitizeContent(_ content: String, redactionStyle: RedactionStyle = .full) -> String {
        guard isSensitiveContent(content) else {
            return content
        }
        
        switch redactionStyle {
        case .full:
            return "[REDACTED - Sensitive Content]"
            
        case .partial:
            // Show first and last few characters
            if content.count > 20 {
                let start = content.prefix(8)
                let end = content.suffix(8)
                return "\(start)...[REDACTED]...\(end)"
            } else {
                return "[REDACTED]"
            }
            
        case .hash:
            // Return a hash of the content
            let hash = SHA256.hash(data: Data(content.utf8))
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            return "[REDACTED - Hash: \(hashString.prefix(16))]"
        }
    }
    
    enum RedactionStyle {
        case full       // Completely redact
        case partial    // Show first/last few characters
        case hash       // Show hash of content
    }
    
    // MARK: - Encryption (for future use)
    
    /// Encrypt sensitive data using symmetric encryption
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return combined
    }
    
    /// Decrypt data
    func decrypt(_ encryptedData: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// Generate a new symmetric key for encryption
    static func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    // MARK: - Clipboard Safety
    
    /// Check if clipboard content should be stored
    func shouldStoreClipboardContent(_ content: String) -> Bool {
        // Don't store if it's sensitive
        if isSensitiveContent(content) {
            logger.warning("🔒 Skipping storage of sensitive clipboard content")
            return false
        }
        
        // Don't store if it's too short (likely just a selection)
        if content.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            return false
        }
        
        // Don't store if it's just whitespace
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        
        return true
    }
}

// MARK: - Errors

enum SecurityError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidKey:
            return "Invalid encryption key"
        }
    }
}

// MARK: - Usage Documentation

/*
 # Security Best Practices for SimpleCP
 
 ## Sensitive Content Detection
 
 Use SecurityManager to check if clipboard content is sensitive before storing:
 
 ```swift
 let content = pasteboard.string(forType: .string)
 
 if SecurityManager.shared.shouldStoreClipboardContent(content) {
     // Safe to store
     clipboardManager.addToHistory(content)
 } else {
     // Skip storing sensitive content
     logger.info("Skipped sensitive content")
 }
 ```
 
 ## Content Sanitization
 
 For logging or debugging, sanitize sensitive content:
 
 ```swift
 let sanitized = SecurityManager.shared.sanitizeContent(
     content,
     redactionStyle: .partial
 )
 logger.debug("Clipboard: \(sanitized)")
 ```
 
 ## Future Encryption Support
 
 When implementing encryption at rest:
 
 ```swift
 let key = SecurityManager.generateKey()
 let encrypted = try SecurityManager.shared.encrypt(
     data,
     using: key
 )
 // Store encrypted data
 try await DataPersistenceManager.shared.save(encrypted, filename: "encrypted.data")
 ```
 
 ## Privacy Considerations
 
 1. **User Consent**: Inform users that clipboard content is being monitored
 2. **Data Retention**: Implement automatic cleanup of old clipboard entries
 3. **Exclusion List**: Allow users to configure apps/patterns to exclude
 4. **Encryption**: Consider encrypting stored clipboard history
 5. **Network**: Never send clipboard content to external servers without consent
 
 ## Recommended Settings UI
 
 Add these options to settings:
 
 - [ ] Enable clipboard history
 - [ ] Exclude sensitive content automatically
 - [ ] Clear history after X days
 - [ ] Encrypt clipboard history at rest
 - [ ] Exclude specific applications
 
 ## macOS Privacy Permissions
 
 SimpleCP requires:
 
 1. **Accessibility** (for paste functionality)
    - System Settings → Privacy & Security → Accessibility
 
 2. **Screen Recording** (if implementing visual features)
    - System Settings → Privacy & Security → Screen Recording
 
 ## Compliance
 
 If distributing SimpleCP:
 
 - Provide clear privacy policy
 - Comply with GDPR (if applicable)
 - Follow Apple's privacy guidelines
 - Be transparent about data collection
 
 ## Testing Security Features
 
 ```swift
 @Test("Sensitive content detection works")
 func sensitiveContentDetection() {
     let manager = SecurityManager.shared
     
     #expect(manager.isSensitiveContent("password: secret123"))
     #expect(manager.isSensitiveContent("API_KEY=abc123"))
     #expect(!manager.isSensitiveContent("Hello, world!"))
 }
 ```
 */
