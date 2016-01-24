//
//  MyCell1.swift
//  table_view
//
//  Created by Shuchen Du on 2015/09/05.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit

class MyCell: UITableViewCell {
    
    // for cells in search table
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var vidTitleLabel: UILabel!
    @IBOutlet weak var duration: UILabel!
    
    // for cells in download table
    @IBOutlet weak var imgView_d: UIImageView!
    @IBOutlet weak var duration_d: UILabel!
    @IBOutlet weak var vidTitleLabel_d: UILabel!
    @IBOutlet weak var format_d: UILabel!
    @IBOutlet weak var size_d: UILabel!
    
    //
    var downloaded: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
