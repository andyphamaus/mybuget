import Foundation

// MARK: - Temporary Model for Task Attachment Handling

struct TempTaskAttachment: Identifiable {
    let id: Int
    let fileName: String
    let size: Int64
    let mimeType: String
    let fileData: Data

    // For compatibility with UI display
    var name: String? { fileName }
}