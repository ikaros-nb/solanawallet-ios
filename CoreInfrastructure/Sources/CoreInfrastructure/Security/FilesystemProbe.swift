//
//  FilesystemProbe.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import Foundation

public protocol FilesystemProbe: Sendable {
    func fileExists(atPath path: String) -> Bool
    func canWrite(toPath path: String) -> Bool
}

public struct SystemFilesystemProbe: FilesystemProbe {
    public init() {}

    public func fileExists(atPath path: String) -> Bool {
        guard !isSimulator else {
            return false
        }
        return FileManager.default.fileExists(atPath: path)
    }

    public func canWrite(toPath path: String) -> Bool {
        guard !isSimulator else {
            return false
        }

        do {
            try "x".write(toFile: path, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}
