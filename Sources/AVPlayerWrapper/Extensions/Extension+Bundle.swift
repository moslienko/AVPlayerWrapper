//
//  Extension+Bundle.swift
//
//
//  Created by Pavel Moslienko on 06.07.2024.
//

import Foundation

public extension Bundle {
    
    public func createFileUrl(forResource fileName: String) -> URL? {
        let components = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard components.count == 2 else {
            return nil
        }
        
        let name = components[0]
        let ext = components[1]
        
        return self.url(forResource: name, withExtension: ext)
    }
}
