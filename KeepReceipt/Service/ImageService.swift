//
//  ImageService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-09.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import UIKit

class ImageService {
    
    static let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let fileTypeString = ".jpeg"
    static let imageQuality = CGFloat(0.6)
    static let maxScaledDimension = CGFloat(integerLiteral: 600)
    static var dateFormat: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss_SSSS"
        return dateFormatter
    }
    
    // Saves the image and returns the filename string to be used as receipt ID
    static func saveImage(for image: UIImage) -> String? {
        if let scaledImage = scaleImage(image: image) {
            
            print("Image successfully scaled to \(scaledImage.size.height)px by \(scaledImage.size.width)px")
            
            let fileName = dateFormat.string(from: Date())
            let pathToWriteTo = documentPath.appendingPathComponent(fileName + fileTypeString)
            do {
                if let imageData = scaledImage.jpegData(compressionQuality: imageQuality) {
                    try imageData.write(to: pathToWriteTo, options: .atomic)
                    return fileName
                }
                print("Failed to get JPEG data from image")
                return nil
            } catch {
                print("Failed to write to path")
                return nil
            }
        } else {
            print("Failed to scale image")
            return nil
        }
    }
    
    // Retrieves the image using the receipt ID
    static func getImage(for imageName: String) -> UIImage? {
        let filePath = documentPath.appendingPathComponent(imageName + fileTypeString)
        return UIImage(contentsOfFile: filePath.relativePath)
    }
    
    static func scaleImage(image: UIImage) -> UIImage? {
        
        var scaledSize = CGSize(width: maxScaledDimension, height: maxScaledDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxScaledDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxScaledDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
}
