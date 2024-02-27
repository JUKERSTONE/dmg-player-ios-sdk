// API.swift

import Foundation

class APIService {
    
    static let shared = APIService()
    
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
