import AppKit
import CloudKit
import Foundation

/// Errors that can occur during sync operations
enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case containerNotAvailable
    case networkUnavailable
    case conflictDetected
    case encryptionFailed
    case decryptionFailed
    case recordNotFound
    case quotaExceeded
    case serverRejected(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to iCloud"
        case .containerNotAvailable:
            return "iCloud container not available"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .conflictDetected:
            return "Sync conflict detected"
        case .encryptionFailed:
            return "Failed to encrypt data for sync"
        case .decryptionFailed:
            return "Failed to decrypt synced data"
        case .recordNotFound:
            return "Record not found in iCloud"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .serverRejected(let reason):
            return "Server rejected request: \(reason)"
        }
    }
}

/// Represents a clipboard item prepared for CloudKit sync
struct SyncableClipboardItem: Codable, Sendable {
    let id: UUID
    let encryptedContent: Data
    let nonce: Data
    let contentType: String  // "text" or "image"
    let timestamp: Date
    let sourceAppBundleID: String?
    let sourceAppName: String?
    let pasteCount: Int
    let isPinned: Bool
    let deviceId: String
    let deviceName: String
    let modifiedAt: Date

    /// CloudKit record type name
    static let recordType = "ClipboardItem"
}

/// Service for syncing clipboard items via CloudKit
/// Uses E2E encryption for all content
actor CloudKitSyncService {

    /// Shared singleton instance
    static let shared = CloudKitSyncService()

    /// CloudKit container identifier
    private let containerIdentifier = "iCloud.com.saneclip.app"

    /// The CloudKit container
    private lazy var container: CKContainer = {
        CKContainer(identifier: containerIdentifier)
    }()

    /// Private database for user-specific data
    private var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    /// Zone for clipboard items
    private let zoneID = CKRecordZone.ID(zoneName: "ClipboardZone", ownerName: CKCurrentUserDefaultName)

    /// Server change token for incremental fetch
    private var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: "cloudkit.changeToken") else {
                return nil
            }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
        }
        set {
            if let token = newValue {
                let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: "cloudkit.changeToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "cloudkit.changeToken")
            }
        }
    }

    /// Unique device identifier for this device
    private var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "cloudkit.deviceId") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "cloudkit.deviceId")
        return newId
    }

    /// Device name for display
    private var deviceName: String {
        Host.current().localizedName ?? "Mac"
    }

    /// Sync state
    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var syncError: Error?

    /// Encryption service for E2E encryption
    private let encryptionService = EncryptionService.shared

    private init() {}

    // MARK: - Setup

    /// Sets up the CloudKit zone and subscription
    func setup() async throws {
        // Check account status
        let status = try await container.accountStatus()
        guard status == .available else {
            throw SyncError.notAuthenticated
        }

        // Create custom zone if needed
        try await createZoneIfNeeded()

        // Set up push notification subscription
        try await setupSubscription()
    }

    /// Creates the custom record zone if it doesn't exist
    private func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            _ = try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
        }
    }

    /// Sets up a subscription for push notifications on changes
    private func setupSubscription() async throws {
        let subscriptionID = "clipboard-changes"

        // Check if subscription already exists
        do {
            _ = try await privateDatabase.subscription(for: subscriptionID)
            return // Already exists
        } catch {
            // Subscription doesn't exist, create it
        }

        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true  // Silent push
        subscription.notificationInfo = notificationInfo

        _ = try await privateDatabase.save(subscription)
    }

    // MARK: - Sync Operations

    /// Uploads a clipboard item to CloudKit
    /// - Parameters:
    ///   - item: The clipboard item to upload
    ///   - isPinned: Whether the item is pinned (tracked separately from ClipboardItem)
    /// - Returns: The CKRecord ID of the uploaded record
    @discardableResult
    func uploadItem(_ item: ClipboardItem, isPinned: Bool = false) async throws -> CKRecord.ID {
        isSyncing = true
        defer { isSyncing = false }

        // Encrypt content
        let (encryptedContent, nonce) = try encryptContent(item.content)

        let contentType: String
        switch item.content {
        case .text: contentType = "text"
        case .image: contentType = "image"
        }

        // Create record
        let recordID = CKRecord.ID(recordName: item.id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: SyncableClipboardItem.recordType, recordID: recordID)

        record["encryptedContent"] = encryptedContent as CKRecordValue
        record["nonce"] = nonce as CKRecordValue
        record["contentType"] = contentType as CKRecordValue
        record["timestamp"] = item.timestamp as CKRecordValue
        record["sourceAppBundleID"] = item.sourceAppBundleID as CKRecordValue?
        record["sourceAppName"] = item.sourceAppName as CKRecordValue?
        record["pasteCount"] = item.pasteCount as CKRecordValue
        record["isPinned"] = isPinned as CKRecordValue
        record["deviceId"] = deviceId as CKRecordValue
        record["deviceName"] = deviceName as CKRecordValue
        record["modifiedAt"] = Date() as CKRecordValue

        do {
            let savedRecord = try await privateDatabase.save(record)
            lastSyncDate = Date()
            syncError = nil
            return savedRecord.recordID
        } catch let error as CKError {
            syncError = error
            throw mapCKError(error)
        }
    }

    /// Fetches all changes since last sync
    /// - Returns: Array of clipboard items from other devices
    func fetchChanges() async throws -> [ClipboardItem] {
        isSyncing = true
        defer { isSyncing = false }

        var changedItems: [ClipboardItem] = []

        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = serverChangeToken

        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID],
            configurationsByRecordZoneID: [zoneID: configuration]
        )

        // Process changed records
        operation.recordWasChangedBlock = { [weak self] _, result in
            guard let self else { return }

            switch result {
            case .success(let record):
                if let item = try? self.decryptRecordSync(record) {
                    changedItems.append(item)
                }
            case .failure:
                break
            }
        }

        // Handle deleted records (we'll need to track these separately)
        operation.recordWithIDWasDeletedBlock = { _, _ in
            // Items deleted from other devices
            // Could notify ClipboardManager to remove
        }

        // Track the latest token to update after completion
        var latestToken: CKServerChangeToken?

        // Save new change token
        operation.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
            latestToken = token
        }

        operation.recordZoneFetchResultBlock = { _, result in
            if case .success(let (token, _, _)) = result {
                latestToken = token
            }
        }

        let items: [ClipboardItem] = try await withCheckedThrowingContinuation { continuation in
            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: changedItems)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            privateDatabase.add(operation)
        }

        // Update token after operation completes (now safe within actor context)
        if let token = latestToken {
            updateChangeToken(token)
        }

        return items
    }

    /// Deletes a clipboard item from CloudKit
    func deleteItem(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        try await privateDatabase.deleteRecord(withID: recordID)
    }

    /// Fetches a specific item by ID
    func fetchItem(id: UUID) async throws -> ClipboardItem? {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)

        do {
            let record = try await privateDatabase.record(for: recordID)
            return try decryptRecord(record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    // MARK: - Push Notification Handling

    /// Called when a push notification indicates changes
    func handlePushNotification() async {
        do {
            let items = try await fetchChanges()
            if !items.isEmpty {
                // Notify ClipboardManager about new items
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .syncedItemsReceived,
                        object: nil,
                        userInfo: ["items": items]
                    )
                }
            }
        } catch {
            syncError = error
        }
    }

    // MARK: - Encryption

    /// Encrypts clipboard content for sync
    private nonisolated func encryptContent(_ content: ClipboardContent) throws -> (Data, Data) {
        let data: Data
        switch content {
        case .text(let string):
            data = Data(string.utf8)
        case .image(let image):
            // Convert NSImage to PNG data for sync
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                throw SyncError.encryptionFailed
            }
            data = pngData
        }

        do {
            return try EncryptionService.shared.encryptData(data)
        } catch {
            throw SyncError.encryptionFailed
        }
    }

    /// Decrypts a CloudKit record into a ClipboardItem
    private func decryptRecord(_ record: CKRecord) throws -> ClipboardItem {
        guard let encryptedContent = record["encryptedContent"] as? Data,
              let nonce = record["nonce"] as? Data,
              let contentType = record["contentType"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            throw SyncError.decryptionFailed
        }

        let decryptedData: Data
        do {
            decryptedData = try encryptionService.decryptData(encryptedContent, nonce: nonce)
        } catch {
            throw SyncError.decryptionFailed
        }

        let content: ClipboardContent
        switch contentType {
        case "text":
            guard let string = String(data: decryptedData, encoding: .utf8) else {
                throw SyncError.decryptionFailed
            }
            content = .text(string)
        case "image":
            // Convert PNG data back to NSImage
            guard let image = NSImage(data: decryptedData) else {
                throw SyncError.decryptionFailed
            }
            content = .image(image)
        default:
            throw SyncError.decryptionFailed
        }

        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let sourceAppBundleID = record["sourceAppBundleID"] as? String
        let sourceAppName = record["sourceAppName"] as? String
        let pasteCount = record["pasteCount"] as? Int ?? 0
        // Note: isPinned is tracked separately in ClipboardManager, not in the model
        // Device info from the record (synced from other device)
        _ = record["deviceId"] as? String
        _ = record["deviceName"] as? String
        _ = record["isPinned"] as? Bool ?? false  // Will be handled by ClipboardManager

        return ClipboardItem(
            id: id,
            content: content,
            timestamp: timestamp,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName,
            pasteCount: pasteCount
        )
    }

    /// Sync version of decryptRecord for use in operation callbacks
    private nonisolated func decryptRecordSync(_ record: CKRecord) throws -> ClipboardItem {
        guard let encryptedContent = record["encryptedContent"] as? Data,
              let nonce = record["nonce"] as? Data,
              let contentType = record["contentType"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            throw SyncError.decryptionFailed
        }

        let decryptedData: Data
        do {
            decryptedData = try EncryptionService.shared.decryptData(encryptedContent, nonce: nonce)
        } catch {
            throw SyncError.decryptionFailed
        }

        let content: ClipboardContent
        switch contentType {
        case "text":
            guard let string = String(data: decryptedData, encoding: .utf8) else {
                throw SyncError.decryptionFailed
            }
            content = .text(string)
        case "image":
            // Convert PNG data back to NSImage
            guard let image = NSImage(data: decryptedData) else {
                throw SyncError.decryptionFailed
            }
            content = .image(image)
        default:
            throw SyncError.decryptionFailed
        }

        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let sourceAppBundleID = record["sourceAppBundleID"] as? String
        let sourceAppName = record["sourceAppName"] as? String
        let pasteCount = record["pasteCount"] as? Int ?? 0
        // isPinned tracked separately in ClipboardManager
        _ = record["isPinned"] as? Bool ?? false

        return ClipboardItem(
            id: id,
            content: content,
            timestamp: timestamp,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName,
            pasteCount: pasteCount
        )
    }

    // MARK: - Helpers

    private func updateChangeToken(_ token: CKServerChangeToken?) {
        serverChangeToken = token
    }

    /// Maps CloudKit errors to SyncError
    private func mapCKError(_ error: CKError) -> SyncError {
        switch error.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .serverRecordChanged:
            return .conflictDetected
        case .quotaExceeded:
            return .quotaExceeded
        case .unknownItem:
            return .recordNotFound
        default:
            return .serverRejected(error.localizedDescription)
        }
    }

    // MARK: - Account Status

    /// Checks if iCloud sync is available
    func isAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    /// Gets the current iCloud account status
    func accountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when synced items are received from CloudKit
    static let syncedItemsReceived = Notification.Name("SaneClipSyncedItemsReceived")
}
