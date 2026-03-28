//
//  APIClient.swift
//  CameraRollSounds
//
//  API client for backend communication
//

import Foundation
import OpenbaseShared
import UIKit

struct ProcessImageResponse: Decodable {
    let jobId: String
    let status: String
    let message: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case message
    }
}

struct JobStatusResponse: Decodable {
    let jobId: String
    let status: String
    let audioUrl: String?
    let description: String?
    let qualityVisualization: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case audioUrl = "audio_url"
        case description
        case qualityVisualization = "quality_visualization"
        case error
    }

    var isComplete: Bool {
        status == "completed"
    }

    var isFailed: Bool {
        status == "failed"
    }

    var isPending: Bool {
        status == "pending" || status == "processing"
    }
}

enum APIError: LocalizedError {
    case invalidImage
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case jobFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the selected image"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        case .jobFailed(let message):
            return "Generation failed: \(message)"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let maxImageDimension: CGFloat = 1024
    private let pollInterval: TimeInterval = 2.0
    private let maxPollAttempts = 90 // 3 minutes max

    private init() {}

    private func resizeImage(_ image: UIImage) -> UIImage {
        let size = image.size

        // Check if resizing is needed
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxImageDimension / size.width, maxImageDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func processImage(_ image: UIImage) async throws -> JobStatusResponse {
        let resizedImage = resizeImage(image)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw APIError.invalidImage
        }

        print("[APIClient] Sending image: \(imageData.count / 1024)KB")

        // Start the job
        let jobResponse = try await startJob(imageData: imageData)
        print("[APIClient] Job started: \(jobResponse.jobId)")

        // Poll for completion
        return try await pollForCompletion(jobId: jobResponse.jobId)
    }

    private func startJob(imageData: Data) async throws -> ProcessImageResponse {
        let base64String = imageData.base64EncodedString()

        guard let url = URL(string: Constants.processImageUrl) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Add session token from AllAuth
        if let sessionToken = await AllAuthClient.shared.sessionToken {
            request.setValue("Token \(sessionToken)", forHTTPHeaderField: "Authorization")
        }

        let body = ["image": base64String]
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Server returned status \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            return try decoder.decode(ProcessImageResponse.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.invalidResponse
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func pollForCompletion(jobId: String) async throws -> JobStatusResponse {
        for attempt in 1...maxPollAttempts {
            print("[APIClient] Polling attempt \(attempt)/\(maxPollAttempts) for job \(jobId)")

            let status = try await checkJobStatus(jobId: jobId)

            if status.isComplete {
                print("[APIClient] Job completed!")
                return status
            }

            if status.isFailed {
                throw APIError.jobFailed(status.error ?? "Unknown error")
            }

            // Wait before next poll
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        throw APIError.serverError("Job timed out after \(maxPollAttempts) attempts")
    }

    private func checkJobStatus(jobId: String) async throws -> JobStatusResponse {
        guard let url = URL(string: Constants.jobStatusUrl(jobId: jobId)) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        // Add session token from AllAuth
        if let sessionToken = await AllAuthClient.shared.sessionToken {
            request.setValue("Token \(sessionToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["error"] as? String {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Server returned status \(httpResponse.statusCode)")
            }

            let decoder = JSONDecoder()
            return try decoder.decode(JobStatusResponse.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.invalidResponse
        } catch {
            throw APIError.networkError(error)
        }
    }
}
