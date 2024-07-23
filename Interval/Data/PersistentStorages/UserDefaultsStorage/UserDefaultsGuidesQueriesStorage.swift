//
//  UserDefaultsGuidesQueriesStorage.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

final class UserDefaultsGuidesQueriesStorage {
    private let maxStorageLimit: Int
    private let guidesQueriesKey = "GuidesQueries"
    private var userDefaults: UserDefaults
    private let backgroundQueue: DispatchQueueType
    
    init(
        maxStorageLimit: Int,
        userDefaults: UserDefaults = UserDefaults.standard,
        backgroundQueue: DispatchQueueType = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.maxStorageLimit = maxStorageLimit
        self.userDefaults = userDefaults
        self.backgroundQueue = backgroundQueue
    }

    private func fetchGuidesQueries() -> [GuideQuery] {
        if let queriesData = userDefaults.object(forKey: guidesQueriesKey) as? Data {
            if let guideQueryList = try? JSONDecoder().decode(GuideQueriesListUDS.self, from: queriesData) {
                return guideQueryList.list.map { $0.toDomain() }
            }
        }
        return []
    }

    private func persist(guidesQueries: [GuideQuery]) {
        let encoder = JSONEncoder()
        let guideQueryUDSs = guidesQueries.map(GuideQueryUDS.init)
        if let encoded = try? encoder.encode(GuideQueriesListUDS(list: guideQueryUDSs)) {
            userDefaults.set(encoded, forKey: guidesQueriesKey)
        }
    }
}

extension UserDefaultsGuidesQueriesStorage: GuidesQueriesStorage {

    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[GuideQuery], Error>) -> Void
    ) {
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }

            var queries = self.fetchGuidesQueries()
            queries = queries.count < self.maxStorageLimit ? queries : Array(queries[0..<maxCount])
            completion(.success(queries))
        }
    }

    func saveRecentQuery(
        query: GuideQuery,
        completion: @escaping (Result<GuideQuery, Error>) -> Void
    ) {
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }

            var queries = self.fetchGuidesQueries()
            self.cleanUpQueries(for: query, in: &queries)
            queries.insert(query, at: 0)
            self.persist(guidesQueries: queries)

            completion(.success(query))
        }
    }
}


// MARK: - Private
extension UserDefaultsGuidesQueriesStorage {

    private func cleanUpQueries(for query: GuideQuery, in queries: inout [GuideQuery]) {
        removeDuplicates(for: query, in: &queries)
        removeQueries(limit: maxStorageLimit - 1, in: &queries)
    }

    private func removeDuplicates(for query: GuideQuery, in queries: inout [GuideQuery]) {
        queries = queries.filter { $0 != query }
    }

    private func removeQueries(limit: Int, in queries: inout [GuideQuery]) {
        queries = queries.count <= limit ? queries : Array(queries[0..<limit])
    }
}
