import AppKit

enum ShortcutAssigner {
    /// Company/vendor prefixes stripped before computing shortcuts.
    /// "Microsoft OneNote" → "onenote", "Google Chrome" → "chrome"
    private static let vendorPrefixes: [String] = [
        "microsoft ", "adobe ", "google ", "apple ", "mozilla ",
        "jetbrains ", "autodesk ", "affinity ", "panic ",
        "bare bones ", "fender ", "native instruments ",
        "focusrite ", "universal audio ", "izotope ",
        "the unarchiver", // single-word special case
    ]

    /// Strips known vendor prefix from a lowercased app name.
    private static func strippedName(_ name: String) -> String {
        for prefix in vendorPrefixes {
            if name.hasPrefix(prefix) {
                let stripped = String(name.dropFirst(prefix.count))
                return stripped.isEmpty ? name : stripped
            }
        }
        return name
    }

    /// Assigns the shortest unique prefix of each app's effective name as its shortcut.
    /// Shortcuts are computed on vendor-stripped names so that e.g.
    /// "Microsoft OneNote" → "o" and "Microsoft Word" → "w".
    static func assign(apps: [NSRunningApplication]) -> [pid_t: String] {
        // Build (pid, effectiveName) — stripped for shortcut computation
        let names: [(pid: pid_t, name: String)] = apps.map {
            let raw = ($0.localizedName ?? "").lowercased()
            return ($0.processIdentifier, strippedName(raw))
        }

        var result = [pid_t: String]()
        var taken = Set<String>()

        for (pid, name) in names {
            guard !name.isEmpty else {
                let fallback = "#\(pid)"
                result[pid] = fallback
                taken.insert(fallback)
                continue
            }

            var assigned = false
            for len in 1 ... name.count {
                let prefix = String(name.prefix(len))
                let isUnique = !names.contains { other in
                    other.pid != pid && other.name.hasPrefix(prefix)
                }
                if isUnique && !taken.contains(prefix) {
                    result[pid] = prefix
                    taken.insert(prefix)
                    assigned = true
                    break
                }
            }

            if !assigned {
                var suffix = 2
                while taken.contains(name + "\(suffix)") { suffix += 1 }
                let s = name + "\(suffix)"
                result[pid] = s
                taken.insert(s)
            }
        }

        return result
    }
}
