//
//  GuidesRepository.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

protocol GuidesRepository {
    @discardableResult
    func fetchGuidesList(
        query: GuideQuery,
        page: Int,
        cached: @escaping (IntervalGuides) -> Void,
        completion: @escaping (Result<IntervalGuides, Error>) -> Void
    ) -> Cancellable?
}
