//
//  IntervalSceneDIContainer.swift
//  Interval
//
//  Created by 김미진 on 7/22/24.
//

import UIKit

final class IntervalSceneDIContainer: IntervalFlowCoordinatorDependencies {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
        let imageDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies

    // MARK: - Persistent Storage
    lazy var guidesQueriesStorage: GuidesQueriesStorage = UserDefaultsGuidesQueriesStorage(maxStorageLimit: 10)
    lazy var guidesResponseCache: GuidesResponseStorage = UserDefaultsGuidesResponseStorage()

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Use Cases
//    func makeSearchGuidesUseCase() -> SearchGuidesUseCase {
//        DefaultSearchGuidesUseCase(
//            guidesRepository: makeGuidesRepository(),
//            guidesQueriesRepository: makeGuidesQueriesRepository()
//        )
//    }
    
    func makeFetchRecentGuideQueriesUseCase(
        requestValue: FetchRecentGuideQueriesUseCase.RequestValue,
        completion: @escaping (FetchRecentGuideQueriesUseCase.ResultValue) -> Void
    ) -> UseCase {
        FetchRecentGuideQueriesUseCase(
            requestValue: requestValue,
            completion: completion,
            guidesQueriesRepository: makeGuidesQueriesRepository()
        )
    }
    
    // MARK: - Repositories
    func makeGuidesRepository() -> GuidesRepository {
        DefaultGuidesRepository(
            dataTransferService: dependencies.apiDataTransferService, 
            cache: guidesResponseCache
        )
    }
    func makeGuidesQueriesRepository() -> GuidesQueriesRepository {
        DefaultGuidesQueriesRepository(
            guidesQueriesPersistentStorage: guidesQueriesStorage
        )
    }
    
//    func makePosterImagesRepository() -> PosterImagesRepository {
//        DefaultPosterImagesRepository(
//            dataTransferService: dependencies.imageDataTransferService
//        )
//    }
//    
//    // MARK: - Guides List
//    func makeGuidesListViewController(actions: GuidesListViewModelActions) -> GuidesListViewController {
//        GuidesListViewController.create(
//            with: makeGuidesListViewModel(actions: actions),
//            posterImagesRepository: makePosterImagesRepository()
//        )
//    }
//    
//    func makeGuidesListViewModel(actions: GuidesListViewModelActions) -> GuidesListViewModel {
//        DefaultGuidesListViewModel(
//            searchGuidesUseCase: makeSearchGuidesUseCase(),
//            actions: actions
//        )
//    }
//    
//    // MARK: - Guide Details
    func makeGuideDetailsViewController(setting intervalSetting: IntervalSetting) -> UIViewController {
//        GuideDetailsViewController.create(
//            with: makeGuidesDetailsViewModel(intervalSetting: IntervalSetting)
//        )
        
        return UIViewController()
    }
//    
//    func makeGuidesDetailsViewModel(movie: Movie) -> MovieDetailsViewModel {
//        DefaultGuideDetailsViewModel(
//            guide: guide,
//            posterImagesRepository: makePosterImagesRepository()
//        )
//    }
//    
//    // MARK: - Movies Queries Suggestions List
//    func makeGuidesQueriesSuggestionsListViewController(didSelect: @escaping GuidesQueryListViewModelDidSelectAction) -> UIViewController {
//        if #available(iOS 13.0, *) { // SwiftUI
//            let view = GuidesQueryListView(
//                viewModelWrapper: makeGuidesQueryListViewModelWrapper(didSelect: didSelect)
//            )
//            return UIHostingController(rootView: view)
//        } else { // UIKit
//            return GuidesQueriesTableViewController.create(
//                with: makeMoviesQueryListViewModel(didSelect: didSelect)
//            )
//        }
//    }
//    
//    func makeGuidesQueryListViewModel(didSelect: @escaping GuidesQueryListViewModelDidSelectAction) -> GuidesQueryListViewModel {
//        DefaultGuidesQueryListViewModel(
//            numberOfQueriesToShow: 10,
//            fetchRecentMovieQueriesUseCaseFactory: makeFetchRecentGuideQueriesUseCase,
//            didSelect: didSelect
//        )
//    }
//
//    @available(iOS 13.0, *)
//    func makeMoviesQueryListViewModelWrapper(
//        didSelect: @escaping MoviesQueryListViewModelDidSelectAction
//    ) -> MoviesQueryListViewModelWrapper {
//        MoviesQueryListViewModelWrapper(
//            viewModel: makeMoviesQueryListViewModel(didSelect: didSelect)
//        )
//    }
//
    // MARK: - Flow Coordinators
    func makeIntervalFlowCoordinator(navigationController: UINavigationController) -> IntervalFlowCoordinator {
        IntervalFlowCoordinator(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
