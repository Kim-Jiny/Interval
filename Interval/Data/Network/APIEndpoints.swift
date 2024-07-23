//
//  APIEndpoints.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

struct APIEndpoints {
    
    static func getGuides(with guidesRequestDTO: GuidesRequestDTO) -> Endpoint<GuidesResponseDTO> {

        return Endpoint(
            path: "3/search/movie",
            method: .get,
            queryParametersEncodable: guidesRequestDTO
        )
    }

    static func getGuidePoster(path: String, width: Int) -> Endpoint<Data> {

        let sizes = [92, 154, 185, 342, 500, 780]
        let closestWidth = sizes
            .enumerated()
            .min { abs($0.1 - width) < abs($1.1 - width) }?
            .element ?? sizes.first!
        
        return Endpoint(
            path: "t/p/w\(closestWidth)\(path)",
            method: .get,
            responseDecoder: RawDataResponseDecoder()
        )
    }
}
