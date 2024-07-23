//
//  UserDefaultsGuidesResponseStorage.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//
import Foundation

final class UserDefaultsGuidesResponseStorage {
    
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Private
    
    private func key(for requestDto: GuidesRequestDTO) -> String {
        return "com.example.moviesResponse.\(requestDto.query).\(requestDto.page)"
    }
    
    private func deleteResponse(for requestDto: GuidesRequestDTO) {
        let key = self.key(for: requestDto)
        userDefaults.removeObject(forKey: key)
    }
}

extension UserDefaultsGuidesResponseStorage: GuidesResponseStorage {
    
    func getResponse(
        for requestDto: GuidesRequestDTO,
        completion: @escaping (Result<GuidesResponseDTO?, Error>) -> Void
    ) {
        let key = self.key(for: requestDto)
        
        if let data = userDefaults.data(forKey: key) {
            do {
                let responseDto = try JSONDecoder().decode(GuidesResponseDTO.self, from: data)
                completion(.success(responseDto))
            } catch {
                completion(.failure(UserDefaultsStorageError.readError(error)))
            }
        } else {
            completion(.success(nil))
        }
    }
    
    func save(
        response responseDto: GuidesResponseDTO,
        for requestDto: GuidesRequestDTO
    ) {
        let key = self.key(for: requestDto)
        
        do {
            let data = try JSONEncoder().encode(responseDto)
            userDefaults.set(data, forKey: key)
        } catch {
            // TODO: - Log to Crashlytics
            debugPrint("UserDefaultsMoviesResponseStorage Unresolved error \(error), \((error as NSError).userInfo)")
        }
    }
}

enum UserDefaultsStorageError: Error {
    case readError(Error)
    case writeError(Error)
}
