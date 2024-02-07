//
//  TimeIntervalExtension.swift
//  DSSNetwork
//
//  Created by David on 07/10/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

public extension TimeInterval {
    static let oneMinute: TimeInterval = 60
    static let fiveMinutes: TimeInterval = 300
    static let tenMinutes: TimeInterval = 600
    static let fifteenMinutes: TimeInterval = 900
    static let halfHour: TimeInterval = 1800
    static let oneHour: TimeInterval = 3600
    static let halfDay: TimeInterval = 12 * oneHour
    static let oneDay: TimeInterval = 24 * 3600
    static let oneWeek: TimeInterval = 7 * oneDay
}
