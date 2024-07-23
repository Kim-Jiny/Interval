//
//  UseCase.swift
//  Interval
//
//  Created by 김미진 on 7/23/24.
//
import Foundation

protocol UseCase {
    @discardableResult
    func start() -> Cancellable?
}
