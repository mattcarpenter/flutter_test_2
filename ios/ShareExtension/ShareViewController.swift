import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

class ShareViewController: UIViewController {

    private let appGroupId = "group.app.stockpot.app"
    private let urlScheme = "app.stockpot.app"

    // UI elements for large file progress
    private var progressView: UIProgressView?
    private var statusLabel: UILabel?
    private var containerView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)

        // Always show a loading indicator immediately so users see something
        showMinimalLoadingUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processSharedItems()
    }

    private func showMinimalLoadingUI() {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        let label = UILabel()
        label.text = "Opening Stockpot..."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 200),
            container.heightAnchor.constraint(equalToConstant: 80),

            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])

        self.containerView = container
        self.statusLabel = label
    }

    // MARK: - Processing

    private func processSharedItems() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeWithError("No items to share")
            return
        }

        let sessionId = UUID().uuidString
        var manifestItems: [[String: Any]] = []
        let dispatchGroup = DispatchGroup()
        var hasLargeFiles = false
        var fileIndex = 0

        // Extract attributedContentText and attributedTitle from extension items (free metadata)
        var attributedContentText: String?
        var attributedTitle: String?

        for extensionItem in extensionItems {
            if attributedContentText == nil, let content = extensionItem.attributedContentText?.string, !content.isEmpty {
                attributedContentText = content
                print("=== Extension Item attributedContentText: \(content)")
            }
            if attributedTitle == nil, let title = extensionItem.attributedTitle?.string, !title.isEmpty {
                attributedTitle = title
                print("=== Extension Item attributedTitle: \(title)")
            }
        }

        // First pass: detect if we need progress UI
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
                   provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    // Estimate size - show progress for any media
                    hasLargeFiles = true
                }
            }
        }

        if hasLargeFiles {
            showProgressUI()
        }

        // Second pass: process items
        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }

            for provider in attachments {
                dispatchGroup.enter()
                let currentIndex = fileIndex
                fileIndex += 1

                processAttachment(
                    provider: provider,
                    sessionId: sessionId,
                    fileIndex: currentIndex
                ) { [weak self] item in
                    if let item = item {
                        DispatchQueue.main.async {
                            manifestItems.append(item)
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Write manifest
            var manifest: [String: Any] = [
                "sessionId": sessionId,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "sourceApp": self.sourceAppBundleId() ?? "unknown",
                "items": manifestItems
            ]

            // Add extension item metadata if available
            if let contentText = attributedContentText {
                manifest["attributedContentText"] = contentText
            }
            if let title = attributedTitle {
                manifest["attributedTitle"] = title
            }

            if self.writeManifest(manifest, sessionId: sessionId) {
                self.openMainApp(sessionId: sessionId)
            } else {
                self.completeWithError("Failed to save shared content")
            }
        }
    }

    private func processAttachment(
        provider: NSItemProvider,
        sessionId: String,
        fileIndex: Int,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        // DEBUG: Log all available types for experimentation
        print("=== Share Provider Debug ===")
        print("Registered types: \(provider.registeredTypeIdentifiers)")
        print("Suggested name: \(provider.suggestedName ?? "nil")")

        // Check for URL first (most common for web sharing)
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                guard let self = self else {
                    completion(nil)
                    return
                }

                if let url = data as? URL {
                    // Check if it's a file URL or web URL
                    if url.isFileURL {
                        // It's a file, copy it
                        self.copyFileFromURL(
                            url: url,
                            sessionId: sessionId,
                            fileIndex: fileIndex,
                            itemType: "data",
                            completion: completion
                        )
                    } else {
                        // It's a web URL - also try to get associated text
                        var item: [String: Any] = [
                            "type": "url",
                            "url": url.absoluteString,
                            "title": provider.suggestedName ?? ""
                        ]

                        // Also extract text if available (for captions, descriptions, etc.)
                        self.extractText(from: provider) { text in
                            if let text = text, !text.isEmpty {
                                item["text"] = text
                            }
                            completion(item)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
            return
        }

        // Check for text using multiple UTTypes
        if let textType = self.findTextType(in: provider) {
            provider.loadItem(forTypeIdentifier: textType, options: nil) { (data, error) in
                if let text = data as? String {
                    completion([
                        "type": "text",
                        "text": text
                    ])
                } else {
                    completion(nil)
                }
            }
            return
        }

        // Check for image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.image.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "image",
                completion: completion
            )
            return
        }

        // Check for movie
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.movie.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "movie",
                completion: completion
            )
            return
        }

        // Generic data/file
        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            copyFileToAppGroup(
                provider: provider,
                typeIdentifier: UTType.data.identifier,
                sessionId: sessionId,
                fileIndex: fileIndex,
                itemType: "data",
                completion: completion
            )
            return
        }

        completion(nil)
    }

    private func copyFileFromURL(
        url: URL,
        sessionId: String,
        fileIndex: Int,
        itemType: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        guard let containerUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            completion(nil)
            return
        }

        let sessionDir = containerUrl.appendingPathComponent("share_sessions/\(sessionId)")

        do {
            try FileManager.default.createDirectory(
                at: sessionDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let fileExtension = url.pathExtension.isEmpty ? "bin" : url.pathExtension
            let fileName = "file_\(fileIndex).\(fileExtension)"
            let destUrl = sessionDir.appendingPathComponent(fileName)

            // Need to access the security-scoped resource for files from other apps
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            try FileManager.default.copyItem(at: url, to: destUrl)

            let attributes = try FileManager.default.attributesOfItem(atPath: destUrl.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"

            var item: [String: Any] = [
                "type": itemType,
                "fileName": fileName,
                "originalFileName": url.lastPathComponent,
                "mimeType": mimeType,
                "sizeBytes": fileSize
            ]

            if itemType == "data" {
                if let uti = UTType(filenameExtension: fileExtension) {
                    item["uniformTypeIdentifier"] = uti.identifier
                }
            }

            DispatchQueue.main.async {
                self.updateProgress(description: "Copied \(url.lastPathComponent)")
            }

            completion(item)

        } catch {
            print("Error copying file from URL: \(error)")
            completion(nil)
        }
    }

    private func copyFileToAppGroup(
        provider: NSItemProvider,
        typeIdentifier: String,
        sessionId: String,
        fileIndex: Int,
        itemType: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] (url, error) in
            guard let self = self, let sourceUrl = url else {
                completion(nil)
                return
            }

            guard let containerUrl = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: self.appGroupId
            ) else {
                completion(nil)
                return
            }

            let sessionDir = containerUrl.appendingPathComponent("share_sessions/\(sessionId)")

            do {
                try FileManager.default.createDirectory(
                    at: sessionDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )

                let fileExtension = sourceUrl.pathExtension.isEmpty ? "bin" : sourceUrl.pathExtension
                let fileName = "file_\(fileIndex).\(fileExtension)"
                let destUrl = sessionDir.appendingPathComponent(fileName)

                try FileManager.default.copyItem(at: sourceUrl, to: destUrl)

                let attributes = try FileManager.default.attributesOfItem(atPath: destUrl.path)
                let fileSize = attributes[.size] as? Int64 ?? 0

                let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"

                var item: [String: Any] = [
                    "type": itemType,
                    "fileName": fileName,
                    "originalFileName": sourceUrl.lastPathComponent,
                    "mimeType": mimeType,
                    "sizeBytes": fileSize
                ]

                if itemType == "data" {
                    item["uniformTypeIdentifier"] = typeIdentifier
                }

                DispatchQueue.main.async {
                    self.updateProgress(description: "Copied \(sourceUrl.lastPathComponent)")
                }

                completion(item)

            } catch {
                print("Error copying file: \(error)")
                completion(nil)
            }
        }
    }

    // MARK: - Manifest Writing

    private func writeManifest(_ manifest: [String: Any], sessionId: String) -> Bool {
        guard let containerUrl = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else {
            return false
        }

        let sessionDir = containerUrl.appendingPathComponent("share_sessions/\(sessionId)")
        let manifestUrl = sessionDir.appendingPathComponent("manifest.json")

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(
                at: sessionDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let data = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
            try data.write(to: manifestUrl)
            return true
        } catch {
            print("Error writing manifest: \(error)")
            return false
        }
    }

    // MARK: - App Opening

    private func openMainApp(sessionId: String) {
        guard let url = URL(string: "\(urlScheme)://share?sessionId=\(sessionId)") else {
            completeWithError("Failed to create URL")
            return
        }

        // Complete the extension and open the URL
        extensionContext?.completeRequest(returningItems: nil) { _ in
            // Use the responder chain to open the URL
            self.openURL(url)
        }
    }

    @objc private func openURL(_ url: URL) {
        // Use selector-based approach for iOS extensions
        // This is the accepted way to open a URL from an extension
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }

        // Fallback: use the selector approach
        let selector = NSSelectorFromString("openURL:")
        responder = self
        while responder != nil {
            if responder!.responds(to: selector) {
                _ = responder!.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }

    // MARK: - Progress UI

    private func showProgressUI() {
        // Remove the minimal loading UI first
        containerView?.removeFromSuperview()

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowOpacity = 0.1
        container.layer.shadowRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let label = UILabel()
        label.text = "Importing..."
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0
        container.addSubview(progress)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 280),
            container.heightAnchor.constraint(equalToConstant: 120),

            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            progress.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            progress.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            progress.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        self.containerView = container
        self.statusLabel = label
        self.progressView = progress
    }

    private func updateProgress(description: String) {
        statusLabel?.text = description
    }

    // MARK: - Helpers

    private func sourceAppBundleId() -> String? {
        // Try to get source app bundle ID from extension context
        // This may not always be available
        return nil
    }

    /// Text UTTypes to check, in priority order
    private var textTypeIdentifiers: [String] {
        [
            UTType.plainText.identifier,       // public.plain-text
            UTType.utf8PlainText.identifier,   // public.utf8-plain-text
            UTType.text.identifier,            // public.text (parent type)
        ]
    }

    /// Find the first matching text type in the provider
    private func findTextType(in provider: NSItemProvider) -> String? {
        for textType in textTypeIdentifiers {
            if provider.hasItemConformingToTypeIdentifier(textType) {
                return textType
            }
        }
        return nil
    }

    /// Extract text from a provider, checking multiple UTTypes
    private func extractText(from provider: NSItemProvider, completion: @escaping (String?) -> Void) {
        guard let textType = findTextType(in: provider) else {
            completion(nil)
            return
        }

        provider.loadItem(forTypeIdentifier: textType, options: nil) { (data, error) in
            completion(data as? String)
        }
    }

    private func completeWithError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.cancelRequest(withError: NSError(
                domain: "ShareExtension",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: message]
            ))
        })
        present(alert, animated: true)
    }
}
