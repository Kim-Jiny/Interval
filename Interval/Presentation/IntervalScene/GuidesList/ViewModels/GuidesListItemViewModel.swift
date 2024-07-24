//
//  GuidesListItemViewModel.swift
//  Interval
//
//  Created by 김미진 on 7/24/24.
//

import Foundation

struct GuidesListItemViewModel: Equatable {
    let title: String
    let overview: String
    let releaseDate: String
    let posterImagePath: String?
}

extension GuidesListItemViewModel {

    init(guide: IntervalSetting) {
        self.title = guide.title ?? ""
        self.posterImagePath = guide.posterPath
        self.overview = guide.overview ?? ""
        if let releaseDate = guide.releaseDate {
            self.releaseDate = "\(NSLocalizedString("Release Date", comment: "")): \(dateFormatter.string(from: releaseDate))"
        } else {
            self.releaseDate = NSLocalizedString("To be announced", comment: "")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
