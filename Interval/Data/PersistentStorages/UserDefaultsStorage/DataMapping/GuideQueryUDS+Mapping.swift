//
//  GuideQueryUDS+Mapping.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

struct GuideQueriesListUDS: Codable {
    var list: [GuideQueryUDS]
}

struct GuideQueryUDS: Codable {
    let query: String
}

extension GuideQueryUDS {
    init(guideQuery: GuideQuery) {
        query = guideQuery.query
    }
}

extension GuideQueryUDS {
    func toDomain() -> GuideQuery {
        return .init(query: query)
    }
}
