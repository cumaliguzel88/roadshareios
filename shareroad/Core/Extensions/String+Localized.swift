//
//  String+Localized.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import Foundation

// MARK: - String Localization Extension
/// Localization için kolaylık extension'ı
/// Kullanım: "key".localized veya "key".localized(with: arg1, arg2)
extension String {
    
    /// Basit localized string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Parametreli localized string
    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
