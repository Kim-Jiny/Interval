//
//  GuidesResponseStorage.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

protocol GuidesResponseStorage {
    func getResponse(
        for request: GuidesRequestDTO,
        completion: @escaping (Result<GuidesResponseDTO?, Error>) -> Void
    )
    func save(response: GuidesResponseDTO, for requestDto: GuidesRequestDTO)
}
