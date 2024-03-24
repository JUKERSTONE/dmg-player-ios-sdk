// API.swift

import Foundation

public class APIService {
    
    static let shared = APIService()
    
    func postData(to url: URL, body: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        // Create a URLRequest for the specified URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        // Specify the content type in the header if necessary
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                completion(.success(data))
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let error = NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid response or data"])
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func fetchData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                completion(.success(data))
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response or data"])
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func parseJSON<T: Decodable>(_ data: Data, type: T.Type) -> T? {
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(T.self, from: data)
            return response
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
