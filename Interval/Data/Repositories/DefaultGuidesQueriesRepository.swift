//
//  DefaultGuidesQueriesRepository.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

final class DefaultGuidesQueriesRepository {
    
    private var guidesQueriesPersistentStorage: GuidesQueriesStorage
    
    init(guidesQueriesPersistentStorage: GuidesQueriesStorage) {
        self.guidesQueriesPersistentStorage = guidesQueriesPersistentStorage
    }
}

extension DefaultGuidesQueriesRepository: GuidesQueriesRepository {
    
    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[GuideQuery], Error>) -> Void
    ) {
        return guidesQueriesPersistentStorage.fetchRecentsQueries(
            maxCount: maxCount,
            completion: completion
        )
    }
    
    func saveRecentQuery(
        query: GuideQuery,
        completion: @escaping (Result<GuideQuery, Error>) -> Void
    ) {
        guidesQueriesPersistentStorage.saveRecentQuery(
            query: query,
            completion: completion
        )
    }
}
