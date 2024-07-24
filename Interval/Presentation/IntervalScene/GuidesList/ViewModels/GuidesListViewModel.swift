//
//  GuidesListViewModel.swift
//  Interval
//
//  Created by 김미진 on 7/22/24.
//

import Foundation

struct GuidesListViewModelActions {
    /// Note: if you would need to edit movie inside Details screen and update this Movies List screen with updated movie then you would need this closure:
    /// showMovieDetails: (Movie, @escaping (_ updated: Movie) -> Void) -> Void
    let showGuideDetails: (IntervalSetting) -> Void
    let showGuideQueriesSuggestions: (@escaping (_ didSelect: GuideQuery) -> Void) -> Void
    let closeGuideQueriesSuggestions: () -> Void
}

enum GuidesListViewModelLoading {
    case fullScreen
    case nextPage
}

protocol GuidesListViewModelInput {
    func viewDidLoad()
    func didLoadNextPage()
    func didSearch(query: String)
    func didCancelSearch()
    func showQueriesSuggestions()
    func closeQueriesSuggestions()
    func didSelectItem(at index: Int)
}

protocol GuidesListViewModelOutput {
    var items: Observable<[GuidesListItemViewModel]> { get }
    var loading: Observable<GuidesListViewModelLoading?> { get }
    var query: Observable<String> { get }
    var error: Observable<String> { get }
    var isEmpty: Bool { get }
    var screenTitle: String { get }
    var emptyDataTitle: String { get }
    var errorTitle: String { get }
    var searchBarPlaceholder: String { get }
}

typealias GuidesListViewModel = GuidesListViewModelInput & GuidesListViewModelOutput

final class DefaultGuidesListViewModel: GuidesListViewModel {

    private let searchGuidesUseCase: SearchGuidesUseCase
    private let actions: GuidesListViewModelActions?

    var currentPage: Int = 0
    var totalPageCount: Int = 1
    var hasMorePages: Bool { currentPage < totalPageCount }
    var nextPage: Int { hasMorePages ? currentPage + 1 : currentPage }

    private var pages: [IntervalGuides] = []
    private var guidesLoadTask: Cancellable? { willSet { guidesLoadTask?.cancel() } }
    private let mainQueue: DispatchQueueType

    // MARK: - OUTPUT

    let items: Observable<[GuidesListItemViewModel]> = Observable([])
    let loading: Observable<GuidesListViewModelLoading?> = Observable(.none)
    let query: Observable<String> = Observable("")
    let error: Observable<String> = Observable("")
    var isEmpty: Bool { return items.value.isEmpty }
    let screenTitle = NSLocalizedString("Movies", comment: "")
    let emptyDataTitle = NSLocalizedString("Search results", comment: "")
    let errorTitle = NSLocalizedString("Error", comment: "")
    let searchBarPlaceholder = NSLocalizedString("Search Movies", comment: "")

    // MARK: - Init
    
    init(
        searchGuidesUseCase: SearchGuidesUseCase,
        actions: GuidesListViewModelActions? = nil,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.searchGuidesUseCase = searchGuidesUseCase
        self.actions = actions
        self.mainQueue = mainQueue
    }

    // MARK: - Private

    private func appendPage(_ guides: IntervalGuides) {
        currentPage = guides.page
        totalPageCount = guides.totalPages

        pages = pages
            .filter { $0.page != guides.page }
            + [guides]

        items.value = pages.guides.map(GuidesListItemViewModel.init)
    }

    private func resetPages() {
        currentPage = 0
        totalPageCount = 1
        pages.removeAll()
        items.value.removeAll()
    }

    private func load(guideQuery: GuideQuery, loading: GuidesListViewModelLoading) {
        self.loading.value = loading
        query.value = guideQuery.query

        guidesLoadTask = searchGuidesUseCase.execute(
            requestValue: .init(query: guideQuery, page: nextPage),
            cached: { [weak self] page in
                self?.mainQueue.async {
                    self?.appendPage(page)
                }
            },
            completion: { [weak self] result in
                self?.mainQueue.async {
                    switch result {
                    case .success(let page):
                        self?.appendPage(page)
                    case .failure(let error):
                        self?.handle(error: error)
                    }
                    self?.loading.value = .none
                }
        })
    }

    private func handle(error: Error) {
        self.error.value = error.isInternetConnectionError ?
            NSLocalizedString("No internet connection", comment: "") :
            NSLocalizedString("Failed loading movies", comment: "")
    }

    private func update(guideQuery: GuideQuery) {
        resetPages()
        load(guideQuery: guideQuery, loading: .fullScreen)
    }
}

// MARK: - INPUT. View event methods

extension DefaultGuidesListViewModel {

    func viewDidLoad() { }

    func didLoadNextPage() {
        guard hasMorePages, loading.value == .none else { return }
        load(guideQuery: .init(query: query.value),
             loading: .nextPage)
    }

    func didSearch(query: String) {
        guard !query.isEmpty else { return }
        update(guideQuery: GuideQuery(query: query))
    }

    func didCancelSearch() {
        guidesLoadTask?.cancel()
    }

    func showQueriesSuggestions() {
        actions?.showGuideQueriesSuggestions(update(guideQuery:))
    }

    func closeQueriesSuggestions() {
        actions?.closeGuideQueriesSuggestions()
    }

    func didSelectItem(at index: Int) {
        actions?.showGuideDetails(pages.guides[index])
    }
}

// MARK: - Private

private extension Array where Element == IntervalGuides {
    var guides: [IntervalSetting] { flatMap { $0.guides } }
}
