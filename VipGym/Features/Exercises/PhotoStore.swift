import UIKit

/// Zdjęcia ćwiczeń użytkownika: tylko lokalnie, w katalogu aplikacji.
enum PhotoStore {
    private static var directory: URL {
        let dir = URL.documentsDirectory.appending(path: "ExercisePhotos", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        // Zmniejszamy do rozsądnego rozmiaru, żeby nie zapełniać telefonu.
        let maxSide: CGFloat = 1600
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do { try jpeg.write(to: directory.appending(path: name)); return name } catch { return nil }
    }

    static func image(named name: String) -> UIImage? {
        UIImage(contentsOfFile: directory.appending(path: name).path)
    }

    static func delete(named name: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: name))
    }
}
