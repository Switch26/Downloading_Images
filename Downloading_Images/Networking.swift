//
//  Networking.swift
//  Downloading_Images
//
//  Created by Serguei Vinnitskii on 2/24/23.
//

import Foundation

let GIFLink = URL(string: "https://assets.objkt.media/file/assets-003/QmeV59TprQazHz8TcrSXT2kijALMwCRvrYegoPrVtRRh5t/artifact")!
public let PNGLink = URL(string: "https://portalcripto.com.br/wp-content/uploads/2021/11/tezosnft.png")!

func getFileURL(forNewFileName newFileName: String) throws -> URL {
    try FileManager.default.url(for: .documentDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
    .appendingPathComponent(newFileName)
}

enum DownloadError: Error {
    case failedToCleanupBeforeCopying
    case failedToCopyToNewLocation(Error)
    case badTemporaryURL
    case failedToDownload(Error)
}


class Networking {
    private init() {} // stops other parts of code from trying to create an instance
    static let shared = Networking() // singleton
    //private let endPoint = URL(string: "http://api.")
}

func download(url: URL, toFile file: URL, completion: @escaping(Result<URL, DownloadError>) -> Void) {
        
    let task = URLSession.shared.downloadTask(with: url) { tempURL, response, optionalError in
        
        //print("response: \(response)\n")
        if let validError = optionalError {
            completion(.failure(.failedToDownload(validError)))
            return
        }
        
        guard let tempURL = tempURL else {
            completion(.failure(.badTemporaryURL))
            return
        }
        
        // cleanup before copying. Of not done, copying same file will return error
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            completion(.failure(.failedToCleanupBeforeCopying))
            return
        }
        
        //print(tempURL)
        
        // copy to new location
        do {
            try FileManager.default.copyItem(at: tempURL, to: file)
        } catch {
            completion(.failure(.failedToCopyToNewLocation(error)))
            return
        }
        
        completion(.success(file))
        return
    }
    task.resume()
    
    FlickrEndpoint.getSearchResults(searchTest: "cats", page: 2).parameters
    


}




enum APIConstants {
  static let host = "api.petfinder.com"
  static let grantType = "client_credentials"
  static let clientId = "YourKeyHere"
  static let clientSecret = "YourSecretHere"
}

protocol RequestProtocol {
    var path: String {get}
    var headers: [ String: String] {get}
    var params: [String: Any] {get}
    var urlParams: [String: String?] {get}
    var addAuthorizationToken: Bool {get}
    var requestType: RequestType {get}
}

enum RequestType: String {
    case GET
    case POST
}

extension RequestProtocol {
    var host: String {
        "http://api"
    }
    var addAuthorizationToken: Bool {
        true
    }
    var params: [String: Any] {
        [:]
    }
    var urlParams: [String: String?] {
        [:]
    }
    var headers: [String: String] {
        [:]
    }
    
    func createURLRequest(authToken: String) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        
        if  !urlParams.isEmpty {
            components.queryItems = urlParams.map{
                URLQueryItem(name: $0, value: $1)
            }
        }
        guard let url = components.url else {
            throw DownloadError.badTemporaryURL //NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestType.rawValue
        
        if !headers.isEmpty {
            urlRequest.allHTTPHeaderFields = headers
        }
        
        if addAuthorizationToken {
            urlRequest.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if !params.isEmpty {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params)
        }
        
        return urlRequest
    }
}





protocol APIManagerProtocol {
    func perform(_ request: RequestProtocol, authToken: String) async throws -> Data
    func requestToken() async throws -> Data
}

class APIManager: APIManagerProtocol {

    private let urlSession: URLSession
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    func perform(_ request: RequestProtocol, authToken: String = "") async throws -> Data {
        
        let (data, response) = try await urlSession.data(for: request.createURLRequest(authToken: authToken))
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DownloadError.badTemporaryURL
        }
        return data
    }
    
    func requestToken() async throws -> Data {
        try await perform(AuthTokenRequest.auth)
    }
}


protocol RequestManagerProtocol {
    func perform<T: Decodable>(_ request: RequestProtocol) async throws -> T
}

class RequestManager: RequestManagerProtocol {
    
    let apiManager: APIManagerProtocol
    let decoder: DataDecoderProtocol
    
    init(apiManager: APIManagerProtocol = APIManager(), parser: DataDecoderProtocol = DataDecoder()) {
        self.apiManager = apiManager
        self.decoder = parser
    }
    
    func perform<T: Decodable>(_ request: RequestProtocol) async throws -> T {
        let authToken = try await requestAccessToken()
        let data = try await apiManager.perform(request, authToken: authToken)
        let decoded: T = try decoder.decode(data: data)
        return decoded
    }
    
    func requestAccessToken() async throws -> String {
        let data = try await apiManager.requestToken()
        let token: APIToken = try decoder.decode(data: data)
        return token.accessToken
    }
}

enum AuthTokenRequest: RequestProtocol {
    case auth
    var path: String { "/path/to/data"}
    var addAuthorizationToken: Bool { false }
    var requestType: RequestType {.POST }
    var params: [String : Any] {
        [
            "grant_type": APIConstants.grantType,
            "client_id": APIConstants.clientId,
            "client_secret": APIConstants.clientSecret
        ]
    }
}

struct APIToken: Codable {
  let tokenType: String
  let expiresIn: Int
  let accessToken: String
}












// Medium Article tutorial
protocol Endpoint {
    var scheme: String { get }
    var baseURL: String { get }
    var path: String {get}
    var parameters: [[String: String]] {get}
    var method: String {get}
}

enum FlickrEndpoint: Endpoint {
    case getSearchResults(searchTest: String, page: Int)
    
    var scheme: String {
        switch self {
        default: return "https"
        }
    }
    
    var baseURL: String {
            switch self {
                default: return "api.flickr.com"
            }
        }
    var path: String {
            switch self {
                case.getSearchResults:
                    return "/services/rest/"
            }
        }
    
    var parameters: [[String : String]] {
        let apiKey = "1342340958324890234"
        switch self {
        case.getSearchResults(let searchText, let page):
            return [
            [ "text": searchText ],
            [ "method": "flickr.photos.search"],
            [ "format": "json"],
            [ "page": String(page)]
            ]
        }
    }
    
    var method: String {
            switch self {
                case.getSearchResults:
                    return "GET"
            }
        }
}
