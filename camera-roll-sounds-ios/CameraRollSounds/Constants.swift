//
//  Constants.swift
//  CameraRollSounds
//
//  Configuration constants
//

import Foundation

enum Constants {
    // MARK: - API Configuration

    /// Base URL for the API backend
    static var apiBaseUrl: String {
        "http://100.81.0.19"
    }

    /// AllAuth URL for authentication
    static var allAuthUrl: String {
        "\(apiBaseUrl)/_allauth/app/v1"
    }

    /// Process image endpoint
    static var processImageUrl: String {
        "\(apiBaseUrl)/api/camera_roll_sounds/process-image/"
    }

    /// Job status endpoint (append job_id)
    static func jobStatusUrl(jobId: String) -> String {
        "\(apiBaseUrl)/api/camera_roll_sounds/job/\(jobId)/"
    }
}
