//
//  StorageItemStatus.swift
//  AlpineConnect
//
//  Created by Jenya Lebid on 12/8/23.
//

import Foundation

public enum StorageItemStatus: String, Codable {
    case cloud
    case downloading
    case uploading
    case pendingUpload = "Pending Upload"
    case pendingDownload = "Pending Download"
    case uploadReady
    case downloadReady
    case downloaded
    case issue
    
    case updating
    case pendingUpdate = "Pending Update"
}

public enum StorageIssueType: String {
    case missingLocally
}

public enum StorageItemIssueAction: String {
    case removeOrUpload
    case chooseLocalOrCloud
    case resetToCloud
    case resetToDownloaded
    case removeOrDownload
    case removeOrDownloadOrIgnore
    case delete
    case fixInvalid
}
