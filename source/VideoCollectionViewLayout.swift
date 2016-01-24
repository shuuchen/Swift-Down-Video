//
//  VideoCollectionViewLayout.swift
//  table_template
//
//  Created by Shuchen Du on 2015/10/12.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit

protocol PinterestLayoutDelegate {
    // 1
    func collectionView(collectionView:UICollectionView,
        heightForPhotoAtIndexPath indexPath:NSIndexPath, withWidth:CGFloat) -> CGFloat
    // 2
    func collectionView(collectionView: UICollectionView,
        heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
}

class VideoCollectionViewLayout: UICollectionViewLayout {
    
    // 1
    var delegate: PinterestLayoutDelegate!
    
    // 2
    var numberOfColumns = 2
    var cellPadding: CGFloat = 6.0
    
    // 3
    private var cache = [UICollectionViewLayoutAttributes]()
    
    // 4
    private var contentHeight: CGFloat  = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return CGRectGetWidth(collectionView!.bounds) - (insets.left + insets.right)
    }
}
