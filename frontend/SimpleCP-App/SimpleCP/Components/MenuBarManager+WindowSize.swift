//
//  MenuBarManager+WindowSize.swift
//  SimpleCP
//
//  Window size management for MenuBarManager
//

import Foundation
import SwiftUI
import AppKit

extension MenuBarManager {
    // MARK: - Window Size Management

    func updateWindowSize() {
        guard let window = menuBarWindow else {
            #if DEBUG
            print("⚠️ No window to update")
            #endif
            return
        }
        guard let button = statusItem?.button else { return }

        let windowDimensions = currentWindowDimensions

        #if DEBUG
        print("📏 Updating window size to: \(windowDimensions.width) x \(windowDimensions.height)")
        #endif

        if let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)

            let xPos = screenFrame.midX - (windowDimensions.width / 2)
            let yPos = screenFrame.minY - windowDimensions.height - 8

            let newFrame = NSRect(x: xPos, y: yPos, width: windowDimensions.width, height: windowDimensions.height)

            window.minSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)
            window.maxSize = NSSize(width: windowDimensions.width, height: windowDimensions.height)

            if window.isVisible {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(newFrame, display: true)
                } completionHandler: {
                    if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                        hostingController.view.setFrameSize(NSSize(width: windowDimensions.width, height: windowDimensions.height))
                    }
                }
            } else {
                window.setFrame(newFrame, display: true)
                if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                    hostingController.view.setFrameSize(NSSize(width: windowDimensions.width, height: windowDimensions.height))
                }
            }
        }
    }

    /// Recreates the window from scratch with the current size settings
    func recreateWindow(andShow: Bool = false) {
        let wasVisible = menuBarWindow?.isVisible ?? false
        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil

        if wasVisible || andShow {
            showPanel()
        }
    }

    /// Updates window dimensions without recreating (for live resize support)
    func updateWindowSize(width: Int, height: Int) {
        let clampedWidth = max(250, min(800, width))
        let clampedHeight = max(300, min(800, height))

        UserDefaults.standard.set(clampedWidth, forKey: "windowWidth")
        UserDefaults.standard.set(clampedHeight, forKey: "windowHeight")

        #if DEBUG
        print("📏 Window size updated: \(clampedWidth)x\(clampedHeight) - will apply when window is next opened")
        #endif

        guard let window = menuBarWindow, window.isVisible else { return }

        let newSize = NSSize(width: CGFloat(clampedWidth), height: CGFloat(clampedHeight))

        if let button = statusItem?.button, let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)

            let xPos = screenFrame.midX - (CGFloat(clampedWidth) / 2)
            let yPos = screenFrame.minY - CGFloat(clampedHeight) - 8

            let newFrame = NSRect(x: xPos, y: yPos, width: CGFloat(clampedWidth), height: CGFloat(clampedHeight))

            window.setFrame(newFrame, display: true, animate: true)
            window.minSize = newSize
            window.maxSize = newSize

            if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
                hostingController.view.setFrameSize(newSize)
            }
        }
    }

    /// Recreates the window from scratch with explicit dimensions
    func recreateWindow(width: Int, height: Int, andShow: Bool = false) {
        let wasVisible = menuBarWindow?.isVisible ?? false

        let clampedWidth = max(250, min(800, width))
        let clampedHeight = max(300, min(800, height))

        #if DEBUG
        print("🔄 Recreating window with size: \(clampedWidth)x\(clampedHeight), wasVisible: \(wasVisible), andShow: \(andShow)")
        #endif

        UserDefaults.standard.set(clampedWidth, forKey: "windowWidth")
        UserDefaults.standard.set(clampedHeight, forKey: "windowHeight")

        menuBarWindow?.orderOut(nil)
        menuBarWindow = nil

        if wasVisible || andShow {
            showPanel()
        }
    }
}
