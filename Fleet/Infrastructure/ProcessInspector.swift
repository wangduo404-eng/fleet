import Foundation

/// Thin wrappers around `kill`/`ps`/`lsof` for checking what's actually
/// running.
enum ProcessInspector {
    /// True if a process with this pid currently exists and is reachable.
    static func isAlive(pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        return kill(pid, 0) == 0
    }

    /// (pid, full executable invocation) for every running process, via `ps`.
    static func runningProcesses() -> [(pid: Int32, command: String)] {
        let output = run("/bin/ps", ["-axo", "pid=,args="])
        return output.split(separator: "\n").compactMap { line -> (Int32, String)? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let spaceIndex = trimmed.firstIndex(of: " ") else { return nil }
            guard let pid = Int32(trimmed[trimmed.startIndex..<spaceIndex]) else { return nil }
            let command = trimmed[trimmed.index(after: spaceIndex)...].trimmingCharacters(in: .whitespaces)
            return (pid, command)
        }
    }

    /// Paths of regular files a process currently has open, via `lsof -Fn`.
    static func openFilePaths(pid: Int32) -> [String] {
        let output = run("/usr/sbin/lsof", ["-p", "\(pid)", "-Fn"])
        return output.split(separator: "\n").compactMap { line in
            line.hasPrefix("n") ? String(line.dropFirst()) : nil
        }
    }

    /// Runs a command and returns its stdout, draining the pipe *before*
    /// waiting for exit. `ps` on a busy machine easily produces more output
    /// than the pipe's kernel buffer (~64KB): calling `waitUntilExit()`
    /// first is a classic deadlock — the child blocks writing to a full
    /// pipe nobody is reading, while we block waiting for it to exit. Also
    /// route stderr to /dev/null rather than a second undrained pipe, which
    /// carries the same risk.
    private static func run(_ executable: String, _ arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return "" }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
