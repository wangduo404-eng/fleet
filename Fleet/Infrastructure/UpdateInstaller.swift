import AppKit
import Foundation

enum UpdateInstallError: Error {
    case downloadFailed
    case mountFailed
    case appNotFoundInImage
    case copyFailed
    case replaceFailed
}

/// Downloads the release DMG, mounts it, and atomically swaps the installed
/// `/Applications/Fleet.app` — then relaunches into the new build. Every
/// step lands on a same-volume temp copy before touching the installed app
/// (`FileManager.replaceItemAt` does the actual swap atomically), so a
/// failure partway through never leaves a half-replaced install.
enum UpdateInstaller {
    private static let installedAppURL = URL(fileURLWithPath: "/Applications/Fleet.app")

    static func downloadAndInstall(
        _ update: AvailableUpdate,
        progress: @escaping @Sendable (String) -> Void
    ) async -> Result<Void, UpdateInstallError> {
        progress("下载中…")
        guard let (downloadedURL, _) = try? await URLSession.shared.download(from: update.dmgURL) else {
            return .failure(.downloadFailed)
        }
        let stagedDMG = FileManager.default.temporaryDirectory
            .appendingPathComponent("Fleet-update-\(UUID().uuidString).dmg")
        guard (try? FileManager.default.moveItem(at: downloadedURL, to: stagedDMG)) != nil else {
            return .failure(.downloadFailed)
        }
        defer { try? FileManager.default.removeItem(at: stagedDMG) }

        progress("安装中…")
        guard let mountPoint = mount(stagedDMG) else {
            return .failure(.mountFailed)
        }
        defer { detach(mountPoint) }

        let sourceApp = mountPoint.appendingPathComponent("Fleet.app")
        guard FileManager.default.fileExists(atPath: sourceApp.path) else {
            return .failure(.appNotFoundInImage)
        }

        let stagedApp = FileManager.default.temporaryDirectory
            .appendingPathComponent("Fleet-\(UUID().uuidString).app")
        guard (try? FileManager.default.copyItem(at: sourceApp, to: stagedApp)) != nil else {
            return .failure(.copyFailed)
        }
        defer { try? FileManager.default.removeItem(at: stagedApp) }

        do {
            _ = try FileManager.default.replaceItemAt(installedAppURL, withItemAt: stagedApp)
        } catch {
            return .failure(.replaceFailed)
        }

        progress("完成，重新启动…")
        relaunch()
        return .success(())
    }

    private static func mount(_ dmgURL: URL) -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", dmgURL.path, "-nobrowse", "-plist"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]] else { return nil }
        for entity in entities {
            if let mountPoint = entity["mount-point"] as? String {
                return URL(fileURLWithPath: mountPoint)
            }
        }
        return nil
    }

    private static func detach(_ mountPoint: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", mountPoint.path, "-quiet"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    /// `createsNewApplicationInstance` is required here — the old process
    /// (still running under the same bundle identifier) would otherwise
    /// just get re-activated instead of a fresh process picking up the
    /// just-replaced bundle contents.
    private static func relaunch() {
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: installedAppURL, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
