//
//  DSSTools.swift
//  DSSNetwork
//
//  Created by David on 31/01/20.
//  Copyright © 2020 DS_Systems. All rights reserved.
//

import Foundation

extension String {
    var snakeCaseToCamelCase: String {
        let items = self.components(separatedBy: "_")
        guard items.count > 1 else { return self }
        var camelCase: String = items.first!
        for n in 1...(items.count - 1) {
            camelCase.append(items[n].capitalized)
        }
        return camelCase
    }
}

final public class DSSTools {
    public static func createModel(className: String, data: Data?, mvcInfo: [DSSTools.ModelInfo: Bool]) {
        guard let data = data else {
            print("DSSTools: Nothing to parse")
            return
        }
        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
            printModel(className, dictionary, 1, mvcInfo)
        } catch {
            print("DSSTools: ", error.localizedDescription)
        }
    }
    
    public static func createModel(className: String, dictionary: [String: Any], mvcInfo: [DSSTools.ModelInfo: Bool]) {
        printModel(className, dictionary, 1, mvcInfo)
    }
    
    public enum ModelInfo { case hideValues, includeCodingKeys }
    static private func printModel(_ structName: String, _ dictionary: [String: Any], _ tab: Int, _ modelInfo: [ModelInfo: Bool]) {
        let hideValues = modelInfo[.hideValues] ?? true
        let includeCodingKeys = modelInfo[.includeCodingKeys] ?? false
        
        let tabSpace = spacing(tab)
        let prevTabSpace = tab > 1 ? spacing(tab - 1) : ""
        var codingKeys: [String: String] = [:]
        print("\(prevTabSpace)struct \(structName): Codable {")
        dictionary.forEach({
            if let value = $0.value as? [String: Any] {
                codingKeys[$0.key.snakeCaseToCamelCase] = "\($0.key)"
                printModel("\($0.key.capitalized)", value, tab + 1, modelInfo)
            } else if let arrayDictionary = $0.value as? [[String: Any]], !arrayDictionary.isEmpty {
                let subclassName = $0.key.capitalized
                codingKeys["\($0.key.snakeCaseToCamelCase)Array"] = "\($0.key)"
                print("\(tabSpace)let \($0.key.snakeCaseToCamelCase)Array: [\(subclassName)]")
                printModel("\(subclassName)", arrayDictionary.first!, tab + 1, modelInfo)
            } else {
                codingKeys[$0.key.snakeCaseToCamelCase] = "\($0.key)"
                var castedValues: [String] = []
                if let value = $0.value as? String {
                    castedValues.append(hideValues ? "String" : "String(\"\(value)\")")
                }
                if let value = $0.value as? Bool {
                    castedValues.append(hideValues ? "Bool" : "Bool(\(value))")
                }
                if let value = $0.value as? Int {
                    castedValues.append(hideValues ? "Int" : "Int(\(value))")
                }
                if let value = $0.value as? Float {
                    castedValues.append(hideValues ? "Float" : "Float(\(value))")
                }
                if let value = $0.value as? Double {
                    castedValues.append(hideValues ? "Double" : "Double(\(value))")
                }
                let values: String
                if castedValues.isEmpty {
                    values = hideValues ? "String?" : "String?(nil)"
                } else if castedValues.count > 1 {
                    castedValues[0] = castedValues.first! + "//"
                    values = castedValues.joined(separator: ", ")
                } else {
                    values = castedValues.joined(separator: ", ")
                }
                print("\(tabSpace)let \($0.key.snakeCaseToCamelCase): \(values)")
            }
        })
        
        if includeCodingKeys { printCodingKeys(varNames: codingKeys, tabSpace: tabSpace) }
        
        print("\(prevTabSpace)}")
    }
    
    public class func debugPrint(_ aClass: AnyClass, description: String) {
        #if DEBUG
        print("\(NSStringFromClass(aClass)): \(description)")
        #endif
    }
    
    static private func printCodingKeys(varNames: [String: String], tabSpace: String) {
        print("\n\(tabSpace)private enum CodingKeys: String, CodingKey {")
        
        varNames.forEach({
            print("\(tabSpace)    case \($0.key) = \"\($0.value)\"")
        })
        print("\(tabSpace)}")
    }
    
    public static func spacing(_ tab: Int) -> String {
        var spacing: String = ""
        for _ in 1...tab {
            spacing.append("  ")
        }
        
        return spacing
    }
}
