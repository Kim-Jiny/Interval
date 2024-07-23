//
//  DefaultGuidesRepository.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//
// **Note**: DTOs structs are mapped into Domains here, and Repository protocols does not contain DTOs

import Foundation

final class DefaultGuidesRepository {

    private let dataTransferService: DataTransferService
    private let cache: GuidesResponseStorage
    private let backgroundQueue: DataTransferDispatchQueue

    init(
        dataTransferService: DataTransferService,
        cache: GuidesResponseStorage,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.cache = cache
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultGuidesRepository: GuidesRepository {
    
    func fetchGuidesList(
        query: GuideQuery,
        page: Int,
        cached: @escaping (IntervalGuides) -> Void,
        completion: @escaping (Result<IntervalGuides, Error>) -> Void
    ) -> Cancellable? {

        let requestDTO = GuidesRequestDTO(query: query.query, page: page)
        let task = RepositoryTask()

        cache.getResponse(for: requestDTO) { [weak self, backgroundQueue] result in

            if case let .success(responseDTO?) = result {
                cached(responseDTO.toDomain())
            }
            guard !task.isCancelled else { return }

            let endpoint = APIEndpoints.getGuides(with: requestDTO)
            task.networkTask = self?.dataTransferService.request(
                with: endpoint,
                on: backgroundQueue
            ) { result in
                switch result {
                case .success(let responseDTO):
                    self?.cache.save(response: responseDTO, for: requestDTO)
                    completion(.success(responseDTO.toDomain()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        return task
    }
}
