//
//  ImageService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-09.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import UIKit

// This class is used to save, retrieve, and work with images within the app
class ImageService {
    
    // Define constants so that saving & retrieval use the same variables
    static let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let fileTypeString = ".jpeg"
    static let imageQuality = CGFloat(0.6) // Arbitrary image quality for jpeg compression
    static let maxScaledDimension = CGFloat(integerLiteral: 600) // 600px is usually good enough for future Google Vision recog
    static var dateFormat: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss_SSSS" // Image created datetime will be used for image ID
        return dateFormatter
    }
    
    // Saves the image and returns the filename string to be used as receipt ID
    static func saveImageAndGetId(for image: UIImage) -> String? {
        
        // Scale image first so we don't take up a lot of internal storage
        if let scaledImage = scaleImage(image: image) {
            
            // Get file name and storage path
            let fileName = dateFormat.string(from: Date())
            let pathToWriteTo = documentPath.appendingPathComponent(fileName + fileTypeString)
            
            do {
                
                // Compress the image
                if let imageData = scaledImage.jpegData(compressionQuality: imageQuality) {
                    
                    // Write the image data, and return its filename
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
    
    // Scales the image such that its max dimension is maxScaledDimension
    static func scaleImage(image: UIImage) -> UIImage? {
        
        var scaledSize = CGSize(width: maxScaledDimension, height: maxScaledDimension)
        var scaleFactor: CGFloat
        
        // If width is greater than height, set width to maxDim and scale height accordingly
        // And vice versa
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxScaledDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxScaledDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        // Draw the UI image into the scaled rect
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
}
