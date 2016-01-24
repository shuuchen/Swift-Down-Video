//
//  MusicViewController.swift
//  table_template
//
//  Created by Shuchen Du on 2015/09/29.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit

class MusicViewController: UIViewController {

    @IBOutlet weak var player: YTPlayerView!
    @IBOutlet weak var dloadBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomSpaceCons: NSLayoutConstraint!
    @IBOutlet weak var videoNameLabel: UILabel!
    
    var videoID: String!
    var videoNameText: String!
    var videoDuration: String!
    var showContainerView = false
    var containerViewController: ContainerViewController!
    var newHeight: CGFloat!
    
    let playParam = [
        "playsinline": 1
    ]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func btnClicked(sender: AnyObject) {
        
        showContainerView = !showContainerView
        showContainerView(showContainerView)
    }
    
    func showContainerView(shown: Bool) {
        
        if showContainerView {
            
            self.dloadBtn.setTitle("Hide", forState: .Normal)
            self.newHeight = 0
            print("show")
            for cvc in self.childViewControllers {
                
                if cvc is ContainerViewController {
                    
                    let containervc = cvc as! ContainerViewController
                    containervc.indicator.startAnimating()
                    containervc.downloadVideoJSON()
                }
            }
        } else {
            print("unshow")
            dloadBtn.setTitle("Download As", forState: .Normal)
            self.newHeight = -containerView.bounds.height
        }

        UIView.animateWithDuration(0.3,
            animations: {
                self.bottomSpaceCons.constant = self.newHeight
                self.view.layoutIfNeeded()
            },
            completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoNameLabel.text = videoNameText
        self.player.loadWithVideoId(videoID, playerVars: playParam)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("MusicViewController memory waining...")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
 
        if segue.identifier == "containerSegue" {
            containerViewController = segue.destinationViewController as! ContainerViewController
            containerViewController.videoID = videoID
            containerViewController.videoDuration = videoDuration
        }
    }
}
