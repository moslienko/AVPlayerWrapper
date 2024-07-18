//
//  Extension+Bundle.swift
//
//
//  Created by Pavel Moslienko on 06.07.2024.
//

import Foundation

public extension Bundle {
    
    /// Creates a file URL for a local resource with the specified name.
    /// - Parameter fileName: The name of the resource file.
    /// - Returns: An optional `URL` pointing to the resource file.
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
