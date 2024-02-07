//
//  DSSLogs.swift
//  DSSNetwork
//
//  Created by David Quispe Aruquipa on 18/12/23.
//  Copyright © 2023 DS_Systems. All rights reserved.
//

import Foundation


class DSSLogs {
    struct LoggingResponse: Decodable {
        let success: Bool
        let logId: UUID
        let date: Date
        
        private enum CodingKeys: String, CodingKey {
            case success
            case logId = "log_id"
            case date
        }
    }
    
    struct LoggingBody: Encodable {
        let timestamp: Double
        let context: String
        let description: String
        let metadata: Data?
    }
    
    struct LoggingError: Decodable {
        let success: Bool
//        let error:
    }
    
//    private var baseUrlString: String { "https://ds-systems-3270cce30131.herokuapp.com" }
    private var baseUrlString: String { "https://cute-bobcats-begin.loca.lt" }
    
    static let shared: DSSLogs = DSSLogs()
    
    private var isEnabled: Bool = true
    
    private var urlComponent: URLComponents? {
        var urlComponent = URLComponents(string: baseUrlString)
        urlComponent?.path = path.first == "/" ? path : "/\(path)"
        return urlComponent
    }
    
    private var path: String { "/log" }
    
    private init() {
    }
    
    func enable() { isEnabled = true }
    
    func disable() { isEnabled = false }
    
    func send(sender: AnyClass, context: String, description: String, metadata: Data?) {
        guard isEnabled else { return }
        send(context: "\(NSStringFromClass(sender))\(context)", description: description, metadata: metadata)
    }
    
    func send(context: String, description: String, metadata: Data?) {
        guard let url = urlComponent?.url else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(
            LoggingBody(
                timestamp: Date().timeIntervalSince1970,
                context: "\(context)",
                description: description,
                metadata: metadata
            )
        )
                
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                #if DEBUG
                print("[DSSLog error] ", error)
                #endif
                return
            }
            
//            if let ddata = data, let dict = try? JSONSerialization.jsonObject(with: ddata) as? [String: Any] {
//                print(dict)
//            }
            
            guard let data, let resp = try? JSONDecoder().decode(LoggingResponse.self, from: data) else {
                #if DEBUG
                print("[DSSLog error] Failed to decode")
                #endif
                return
            }
            
            print(resp)
        }.resume()
    }
}
