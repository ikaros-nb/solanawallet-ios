//
//  JailbreakDetectorTests.swift
//  CoreInfrastructure
//
//  Created by Nicolas Bouème on 29/04/2026.
//

import CoreInfrastructure
import Foundation
import Testing

struct FakeFilesystemProbe: FilesystemProbe {
    let existingPaths: Set<String>
    let writablePaths: Set<String>
    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }

    func canWrite(toPath path: String) -> Bool {
        writablePaths.contains(path)
    }
}

struct FakeURLOpener: URLOpener {
    let openableSchemes: Set<String>
    func canOpen(_ url: URL) async -> Bool {
        openableSchemes.contains(url.absoluteString)
    }
}

private func makeCleanProbe() -> FakeFilesystemProbe {
    FakeFilesystemProbe(existingPaths: [], writablePaths: [])
}

private func makeCleanOpener() -> FakeURLOpener {
    FakeURLOpener(openableSchemes: [])
}

struct JailbreakDetectorTests {
    @Test
    func `detect when all checks clean returns none`() async {
        let detector = JailbreakDetector(
            probe: makeCleanProbe(),
            urlOpener: makeCleanOpener()
        )
        #expect(await detector.detect() == .none)
    }

    @Test(arguments: JailbreakDetector.suspiciousAppsPaths)
    func `detect when suspicious app path exists returns suspected`(path: String) async {
        let detector = JailbreakDetector(
            probe: FakeFilesystemProbe(existingPaths: [path], writablePaths: []),
            urlOpener: makeCleanOpener()
        )
        #expect(await detector.detect() == .suspected, "Path \(path) should trigger detection")
    }

    @Test(arguments: JailbreakDetector.suspiciousSystemPaths)
    func `detect when suspicious system path exists returns suspected`(path: String) async {
        let detector = JailbreakDetector(
            probe: FakeFilesystemProbe(existingPaths: [path], writablePaths: []),
            urlOpener: makeCleanOpener()
        )
        #expect(await detector.detect() == .suspected, "Path \(path) should trigger detection")
    }

    @Test
    func `detect when sandbox writable returns suspected`() async {
        let detector = JailbreakDetector(
            probe: FakeFilesystemProbe(
                existingPaths: [],
                writablePaths: [JailbreakDetector.sandboxProbePath]
            ),
            urlOpener: makeCleanOpener()
        )
        #expect(await detector.detect() == .suspected)
    }

    @Test(arguments: JailbreakDetector.suspiciousURLSchemes)
    func `detect when URL scheme openable returns suspected`(scheme: String) async {
        let detector = JailbreakDetector(
            probe: makeCleanProbe(),
            urlOpener: FakeURLOpener(openableSchemes: [scheme])
        )
        #expect(await detector.detect() == .suspected, "Scheme \(scheme) should trigger detection")
    }
}
