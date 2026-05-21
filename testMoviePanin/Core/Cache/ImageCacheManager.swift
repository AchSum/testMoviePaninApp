import UIKit

// MARK: - ImageCacheManager
final class ImageCacheManager {

    static let shared = ImageCacheManager()

    // Memory cache
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit       = CacheConstants.imageMemoryCacheCount
        cache.totalCostLimit   = 50 * 1024 * 1024  // 50 MB memory
        return cache
    }()

    // Disk cache directory
    private let diskCacheURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("CineTrackImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let queue = DispatchQueue(label: "com.cinetrack.imagecache", attributes: .concurrent)
    private var activeTasks: [String: URLSessionDataTask] = [:]
    private let taskLock = NSLock()

    private init() {}

    // MARK: - Load Image (Memory → Disk → Network)
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString

        // 1️⃣ Memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            completion(cached)
            return
        }

        // 2️⃣ Disk cache
        queue.async { [weak self] in
            guard let self else { return }
            if let diskImage = self.loadFromDisk(key: key) {
                self.memoryCache.setObject(diskImage, forKey: key as NSString)
                completion(diskImage)
                return
            }

            // 3️⃣ Download from network
            self.downloadImage(from: url, key: key, completion: completion)
        }
    }

    // MARK: - Download
    private func downloadImage(from url: URL, key: String, completion: @escaping (UIImage?) -> Void) {
        taskLock.lock()
        guard activeTasks[key] == nil else {
            taskLock.unlock()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            self.taskLock.lock()
            self.activeTasks.removeValue(forKey: key)
            self.taskLock.unlock()

            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            self.memoryCache.setObject(image, forKey: key as NSString)
            self.saveToDisk(data: data, key: key)
            completion(image)
        }
        activeTasks[key] = task
        taskLock.unlock()
        task.resume()
    }

    // MARK: - Disk I/O
    private func diskURL(for key: String) -> URL {
        let filename = key.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
        return diskCacheURL.appendingPathComponent(filename)
    }

    private func loadFromDisk(key: String) -> UIImage? {
        let url = diskURL(for: key)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    private func saveToDisk(data: Data, key: String) {
        let url = diskURL(for: key)
        try? data.write(to: url, options: .atomic)
        manageDiskCacheSize()
    }

    // MARK: - Disk Size Management
    private func manageDiskCacheSize() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let fm = FileManager.default
            guard let files = try? fm.contentsOfDirectory(
                at: self.diskCacheURL,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            ) else { return }

            var totalSize = files.compactMap { url -> Int? in
                (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
            }.reduce(0, +)

            guard totalSize > CacheConstants.imageDiskCacheLimit else { return }

            // Remove oldest files first
            let sorted = files.sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return d1 < d2
            }

            for file in sorted {
                guard totalSize > CacheConstants.imageDiskCacheLimit else { break }
                if let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    try? fm.removeItem(at: file)
                    totalSize -= size
                }
            }
        }
    }

    // MARK: - Cancel & Clear
    func cancelLoad(for url: URL) {
        taskLock.lock()
        activeTasks[url.absoluteString]?.cancel()
        activeTasks.removeValue(forKey: url.absoluteString)
        taskLock.unlock()
    }

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
}
