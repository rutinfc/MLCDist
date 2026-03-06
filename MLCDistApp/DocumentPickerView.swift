import SwiftUI
import UniformTypeIdentifiers

/// iOS Files에서 zip 파일을 선택하여 import
struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.zip], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destZipURL = documentsURL.appending(path: url.lastPathComponent)

            var urlToUse: URL?
            do {
                if FileManager.default.fileExists(atPath: destZipURL.path) {
                    try FileManager.default.removeItem(at: destZipURL)
                }
                try FileManager.default.copyItem(at: url, to: destZipURL)
                urlToUse = destZipURL
            } catch {
                // copyItem 실패 시 Data로 읽어서 저장 (보안 스코프 해제 전에 완료)
                do {
                    let data = try Data(contentsOf: url)
                    try data.write(to: destZipURL)
                    urlToUse = destZipURL
                } catch {
                    urlToUse = nil
                }
            }

            // 복사 실패 시 원본 URL 전달 → importModelZip에서 접근 실패 시 에러 메시지 표시
            let urlToPass = urlToUse ?? url
            DispatchQueue.main.async { [onPick] in
                onPick(urlToPass)
            }
        }
    }
}
