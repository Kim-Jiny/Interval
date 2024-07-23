//
//  GuidesQueriesStorage.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

protocol GuidesQueriesStorage {
    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[GuideQuery], Error>) -> Void
    )
    func saveRecentQuery(
        query: GuideQuery,
        completion: @escaping (Result<GuideQuery, Error>) -> Void
    )
}
