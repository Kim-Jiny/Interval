//
//  IntervalSetting.swift
//  Interval
//
//  Created by 김미진 on 7/22/24.
//

import Foundation

struct IntervalSetting: Equatable, Identifiable {
    typealias Identifier = String
    
    enum SettingType {
        case stretching
        case running
        case other
    }
    
    let id: Identifier
    let title: String?
    let settingType: SettingType?
    let posterPath: String?
    let overview: String?
    let releaseDate: Date?
}

struct IntervalGuides: Equatable {
    let page: Int
    let totalPages: Int
    let guides: [IntervalSetting]
}
