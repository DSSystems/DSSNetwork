//
//  StringExtension.swift
//  DSSNetwork
//
//  Created by David on 10/10/19.
//  Copyright © 2019 DS_Systems. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        let comment: String = (Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String) ?? "-"
        return NSLocalizedString(self, comment: comment)
    }
    
    var toData: Data? { return self.data(using: .utf8) }
}
