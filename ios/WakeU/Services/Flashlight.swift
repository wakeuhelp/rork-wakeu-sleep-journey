//
//  Flashlight.swift
//  WakeU
//

import AVFoundation

/// Simple torch toggle for the night-time emergency flashlight shortcut.
enum Flashlight {
    static func toggle(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("[Flashlight] error: \(error.localizedDescription)")
        }
    }
}
