//
//  FetchRecentGuideQueriesUseCase.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

// This is another option to create Use Case using more generic way
final class FetchRecentGuideQueriesUseCase: UseCase {

    struct RequestValue {
        let maxCount: Int
    }
    typealias ResultValue = (Result<[GuideQuery], Error>)

    private let requestValue: RequestValue
    private let completion: (ResultValue) -> Void
    private let guidesQueriesRepository: GuidesQueriesRepository

    init(
        requestValue: RequestValue,
        completion: @escaping (ResultValue) -> Void,
        guidesQueriesRepository: GuidesQueriesRepository
    ) {

        self.requestValue = requestValue
        self.completion = completion
        self.guidesQueriesRepository = guidesQueriesRepository
    }
    
    func start() -> Cancellable? {

        guidesQueriesRepository.fetchRecentsQueries(
            maxCount: requestValue.maxCount,
            completion: completion
        )
        return nil
    }
}
