//
//  GuidesResponseDTO+Mapping.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//

import Foundation

// MARK: - Data Transfer Object

struct GuidesResponseDTO: Codable {
    private enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "total_pages"
        case guides = "results"
    }
    let page: Int
    let totalPages: Int
    let guides: [GuideDTO]
}

extension GuidesResponseDTO {
    struct GuideDTO: Codable {
        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case settingType
            case posterPath = "poster_path"
            case overview
            case releaseDate = "release_date"
        }
        enum SettingTypeDTO: String, Codable {
            case stretching
            case running
            case other
        }
        let id: Int
        let title: String?
        let settingType: SettingTypeDTO?
        let posterPath: String?
        let overview: String?
        let releaseDate: String?
    }
}

// MARK: - Mappings to Domain

extension GuidesResponseDTO {
    func toDomain() -> IntervalGuides {
        return .init(page: page,
                     totalPages: totalPages,
                     guides: guides.map { $0.toDomain() })
    }
}

extension GuidesResponseDTO.GuideDTO {
    func toDomain() -> IntervalSetting {
        return .init(id: IntervalSetting.Identifier(id),
                     title: title,
                     settingType: settingType?.toDomain(),
                     posterPath: posterPath,
                     overview: overview,
                     releaseDate: dateFormatter.date(from: releaseDate ?? ""))
    }
}

extension GuidesResponseDTO.GuideDTO.SettingTypeDTO {
    func toDomain() -> IntervalSetting.SettingType {
        switch self {
        case .stretching:
                .stretching
        case .running:
                .running
        case .other:
                .other
        }
    }
}

// MARK: - Private

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()
