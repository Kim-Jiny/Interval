import UIKit

protocol IntervalFlowCoordinatorDependencies {
//    func makeGuidesListViewController(actions: GuidesListViewModelActions) -> GuidesListViewController
    func makeGuideDetailsViewController(setting: IntervalSetting) -> UIViewController
}

final class IntervalFlowCoordinator {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: IntervalFlowCoordinatorDependencies
    
    init(navigationController: UINavigationController,
         dependencies: IntervalFlowCoordinatorDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    
    func start() {
        
    }
    
    
    private func showGuideDetails(setting: IntervalSetting) {
        
    }
}
