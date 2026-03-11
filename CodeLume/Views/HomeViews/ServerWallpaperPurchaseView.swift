import SwiftUI
import AppKit
import StoreKit
import Foundation

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate {
    var onProgress: ((Double) -> Void)?
    private var continuation: CheckedContinuation<URL, Error>?

    func startDownload(from url: URL, session: URLSession) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        onProgress?(max(0, min(1, progress)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("DownloadTemp-\(UUID().uuidString)")
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            continuation?.resume(returning: destination)
            continuation = nil
        } catch {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

struct ServerWallpaperPurchaseView: View {
    let wallpaper: WallpaperTable
    private let actionButtonWidth: CGFloat = 80

    @StateObject private var iapManager = IAPManager.shared
    @State private var creditsBalance: Int = 0
    @State private var hasPurchased = false
    @State private var isLoading = false
    @State private var hasInitializedForCurrentWallpaper = false
    @State private var isDownloadingWallpaper = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloadedLocally = false
    @State private var downloadTask: Task<Void, Never>?
    @State private var activeDownloadSession: URLSession?

    private let supabase = SupabaseManager.shared

    private var creditsCost: Int {
        return wallpaper.creditsCost
    }

    private var selectedProduct: Product? {
        iapManager.products.first(where: { product in
            if let package = iapManager.creditPackages.first(where: { $0.productId == product.id }) {
                return package.credits >= creditsCost
            }
            return false
        })
    }

    var body: some View {
        HStack() {
            Text("Credits: \(creditsCost)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            if hasPurchased {
                HStack(spacing: 8) {
                    if isDownloadingWallpaper {
                        ProgressView(value: downloadProgress, total: 1.0)
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .frame(width: 16, height: 16)
                    }

                    Button {
                        startDownloadTask()
                    } label: {
                        Text(isDownloadedLocally ? "已下载" : "Download")
                            .frame(width: actionButtonWidth)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            } else {
                HStack(spacing: 8) {
                    Button {
                        Task { await buyWallpaper() }
                    } label: {
                        Text("Buy")
                            .frame(width: actionButtonWidth)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    if creditsBalance < creditsCost {
                        Button {
                            Task { await topUpCredits() }
                        } label: {
                            Text("Top up")
                                .frame(width: actionButtonWidth)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading || selectedProduct == nil)
                    }
                }
            }
        }
        .onChange(of: wallpaper.id) { _, _ in
            hasInitializedForCurrentWallpaper = false
        }
        .task(id: wallpaper.id) {
            guard !hasInitializedForCurrentWallpaper else { return }
            hasInitializedForCurrentWallpaper = true
            await iapManager.loadCreditProducts()
            await refreshState()
        }
        .onDisappear {
            cancelCurrentDownload()
        }
    }

    private func startDownloadTask() {
        guard downloadTask == nil else { return }
        downloadTask = Task {
            await downloadWallpaper()
            await MainActor.run {
                downloadTask = nil
            }
        }
    }

    private func cancelCurrentDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        activeDownloadSession?.invalidateAndCancel()
        activeDownloadSession = nil

        isDownloadingWallpaper = false
        isLoading = false
        downloadProgress = 0
    }

    private func refreshState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            creditsBalance = try await supabase.getUserCredits()
            hasPurchased = try await supabase.hasPurchasedWallpaper(wallpaperId: wallpaper.id)
            isDownloadedLocally = checkLocalDownloadedState()
        } catch {
            guard !isCancellationError(error) else { return }
            Alert(title: "Load failed", message: error.localizedDescription)
        }
    }

    private func topUpCredits() async {
        guard let product = selectedProduct else {
            Alert(title: "Top up unavailable", message: "No matching credit package found.")
            return
        }

        let success = await iapManager.purchase(product: product)
        if success {
            await refreshState()
        } else if let message = iapManager.lastErrorMessage {
            Alert(title: "Purchase failed", message: message)
        }
    }

    private func buyWallpaper() async {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await supabase.purchaseWallpaperWithCredits(wallpaperId: wallpaper.id)
            creditsBalance = try await supabase.getUserCredits()
            hasPurchased = true
        } catch {
            guard !isCancellationError(error) else { return }
            Alert(title: "Buy failed", message: error.localizedDescription)
        }
    }

    private func downloadWallpaper() async {
        isLoading = true
        isDownloadingWallpaper = true
        downloadProgress = 0
        defer {
            isLoading = false
            isDownloadingWallpaper = false
            activeDownloadSession = nil
        }

        do {
            let url = try await supabase.getPurchasedWallpaperDownloadURL(wallpaperId: wallpaper.id)
            try await downloadAndImportWallpaper(from: url)
            downloadProgress = 1
            isDownloadedLocally = true
            Alert(title: "Download success", message: "Wallpaper has been imported to local library.")
            NotificationCenter.default.post(name: .refreshLocalWallpaperList, object: nil)
        } catch {
            guard !isCancellationError(error) else { return }
            Alert(title: "Download failed", message: error.localizedDescription)
        }
    }

    private func downloadAndImportWallpaper(from remoteURL: URL) async throws {
        let fileManager = FileManager.default
        let tempRoot = fileManager.temporaryDirectory.appendingPathComponent("CodelumeDownload-\(UUID().uuidString)", isDirectory: true)

        try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: tempRoot)
        }

        let downloadedFileURL = try await downloadFileWithProgress(from: remoteURL)

        let suggestedName = remoteURL.lastPathComponent.isEmpty ? "wallpaper_\(wallpaper.id.uuidString.lowercased()).bundle.zip" : remoteURL.lastPathComponent
        let localArchiveURL = tempRoot.appendingPathComponent(suggestedName)
        try? fileManager.removeItem(at: localArchiveURL)
        try fileManager.moveItem(at: downloadedFileURL, to: localArchiveURL)

        let bundleURL: URL
        if localArchiveURL.pathExtension.lowercased() == "zip" {
            let extractDirectory = tempRoot.appendingPathComponent("unzipped", isDirectory: true)
            try fileManager.createDirectory(at: extractDirectory, withIntermediateDirectories: true)
            try unzipArchive(at: localArchiveURL, to: extractDirectory)

            guard let extractedBundle = findSingleTopLevelBundle(in: extractDirectory) else {
                throw NSError(domain: "DownloadImport", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Downloaded zip must contain exactly one top-level .bundle."])
            }
            bundleURL = extractedBundle
        } else if localArchiveURL.pathExtension.lowercased() == "bundle" {
            bundleURL = localArchiveURL
        } else {
            throw NSError(domain: "DownloadImport", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Unsupported downloaded file format: \(localArchiveURL.pathExtension)"])
        }

        guard checkWallpaperBundle(bundleURL) else {
            throw NSError(domain: "DownloadImport", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Imported wallpaper bundle format is invalid."])
        }

        guard let wallpaperSaveURL = getWallpaperSaveURL() else {
            throw NSError(domain: "DownloadImport", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Failed to get local wallpaper directory."])
        }

        let destinationURL = wallpaperSaveURL.appendingPathComponent("\(wallpaper.id.uuidString.lowercased()).bundle")
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: bundleURL, to: destinationURL)

        let bundleName = destinationURL.deletingPathExtension().lastPathComponent
        DatabaseManger.shared.addWallpaper(bundleName)
        Logger.info("Imported downloaded wallpaper bundle at: \(destinationURL.path)")
    }

    private func downloadFileWithProgress(from remoteURL: URL) async throws -> URL {
        let delegate = DownloadProgressDelegate()
        delegate.onProgress = { progress in
            Task { @MainActor in
                self.downloadProgress = progress
            }
        }

        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        await MainActor.run {
            self.activeDownloadSession = session
        }
        defer { session.invalidateAndCancel() }
        return try await delegate.startDownload(from: remoteURL, session: session)
    }

    private func unzipArchive(at sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", sourceURL.path, destinationURL.path]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errorData, encoding: .utf8) ?? "Failed to unzip archive."
            throw NSError(domain: "DownloadImport", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func findSingleTopLevelBundle(in directoryURL: URL) -> URL? {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return nil
        }

        let bundles = entries.filter { $0.pathExtension.lowercased() == "bundle" }
        return bundles.count == 1 ? bundles[0] : nil
    }

    private func checkLocalDownloadedState() -> Bool {
        guard let wallpaperSaveURL = getWallpaperSaveURL() else {
            return false
        }

        let fileManager = FileManager.default
        let wallpaperIdLower = wallpaper.id.uuidString.lowercased()
        let canonicalURL = wallpaperSaveURL.appendingPathComponent("\(wallpaperIdLower).bundle")
        if fileManager.fileExists(atPath: canonicalURL.path) {
            return true
        }

        // Backward compatibility: previously downloaded bundles may use non-canonical names.
        guard let entries = try? fileManager.contentsOfDirectory(at: wallpaperSaveURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return false
        }

        return entries.contains { url in
            url.pathExtension.lowercased() == "bundle" && url.lastPathComponent.lowercased().contains(wallpaperIdLower)
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
