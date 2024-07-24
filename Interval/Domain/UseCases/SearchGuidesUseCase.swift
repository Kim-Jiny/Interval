//
//  SearchGuidesUseCase.swift
//  Interval
//
//  Created by 김미진 on 7/24/24.
//

import Foundation

protocol SearchGuidesUseCase {
    func execute(
        requestValue: SearchGuidesUseCaseRequestValue,
        cached: @escaping (IntervalGuides) -> Void,
        completion: @escaping (Result<IntervalGuides, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultSearchGuidesUseCase: SearchGuidesUseCase {

    private let guidesRepository: GuidesRepository
    private let guidesQueriesRepository: GuidesQueriesRepository

    init(
        guidesRepository: GuidesRepository,
        guidesQueriesRepository: GuidesQueriesRepository
    ) {

        self.guidesRepository = guidesRepository
        self.guidesQueriesRepository = guidesQueriesRepository
    }

    func execute(
        requestValue: SearchGuidesUseCaseRequestValue,
        cached: @escaping (IntervalGuides) -> Void,
        completion: @escaping (Result<IntervalGuides, Error>) -> Void
    ) -> Cancellable? {

        return guidesRepository.fetchGuidesList(
            query: requestValue.query,
            page: requestValue.page,
            cached: cached,
            completion: { result in

            if case .success = result {
                self.guidesQueriesRepository.saveRecentQuery(query: requestValue.query) { _ in }
            }

            completion(result)
        })
    }
}

struct SearchGuidesUseCaseRequestValue {
    let query: GuideQuery
    let page: Int
}
