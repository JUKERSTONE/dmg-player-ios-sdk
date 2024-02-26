import Foundation

class APIService {
    
    // Shared singleton instance
    static let shared = APIService()
    
    // Generic function to make API calls
    func fetchData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Check for errors, return if found
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for valid HTTP response and data
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                completion(.success(data))
            } else {
                // Handle unexpected response
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response or data"])
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // Helper function to parse JSON data
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
