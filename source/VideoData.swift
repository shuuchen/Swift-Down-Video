//
//  VideoData.swift
//  
//
//  Created by Shuchen Du on 2015/10/24.
//
//

import Foundation
import CoreData

@objc(VideoData)
class VideoData: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var duration: String
    @NSManaged var format: String
    @NSManaged var size: String
    @NSManaged var resumeData: NSData
    @NSManaged var originalUrl: String

}
