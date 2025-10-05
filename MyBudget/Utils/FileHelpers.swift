import Foundation
import UniformTypeIdentifiers

// MARK: - File Size Utility

func formatFileSize(_ size: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: size)
}

// MARK: - URL Extension for MIME Type

extension URL {
    var mimeType: String? {
        guard let uti = UTType(filenameExtension: self.pathExtension) else {
            return nil
        }
        return uti.preferredMIMEType
    }
}