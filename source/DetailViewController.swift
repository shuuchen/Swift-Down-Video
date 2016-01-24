//
//  DetailViewController.swift
//  table_view
//
//  Created by Shuchen Du on 2015/09/07.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var videoPlayerView: AVPlayerView!
    @IBOutlet weak var seekBar: UISlider!
    @IBOutlet weak var downloadIndicator: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var progressingView: UIView!
    @IBOutlet weak var playerBackgroundView: AVPlayerView!
    
    // video url
    var videoUrl: NSURL?
    
    // 再生用のアイテム.
    var playerItem : AVPlayerItem!
    
    // AVPlayer.
    var videoPlayer : AVPlayer!
    
    // whether download is over
    var videoDownloaded: Bool!
    
    // video download percent
    var pp: Int = 0
    var pp_cgfloat = CGFloat(0.0)
    
    // download background image path
    var backgroundImgPath: String!
    
    // video info
    var videoTitle: String!
    var videoFormat: String!
    var videoSize: String!
    
    // video download percent notification handler
    func handleVideoDownloadPercentNotif(notif: NSNotification) {

        // task description
        let title = notif.userInfo!["title"] as! String
        let format = notif.userInfo!["format"] as! String
        let size = notif.userInfo!["size"] as! String
        
        // compare with that in core data
        if !(title == self.videoTitle &&
            format == self.videoFormat && size == self.videoSize) {
            return
        }
        
        // video download percent
        let p: AnyObject? = notif.userInfo!["percent"]
        let p_double: Double
        if let _p: AnyObject = p {
            p_double = _p as! Double
        } else {
            p_double = 0
        }
        let p_int = Int(p_double * 100)
        let p_cgfloat = CGFloat(p_double)
        
        pp = (p_int > pp) ? p_int : pp
        pp_cgfloat = (p_cgfloat > pp_cgfloat) ? p_cgfloat : pp_cgfloat
        
        // progressing view
        progressView.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.5)
        progressingView.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.5)
        
        // update UI
        dispatch_async(dispatch_get_main_queue(), {
            self.percentLabel.text = "\(self.pp)%"
            self.progressingView.frame.size.width =
                self.progressView.frame.size.width * self.pp_cgfloat
            
            if let img = UIImage(contentsOfFile: self.backgroundImgPath) {
                self.playerBackgroundView.backgroundColor =
                    UIColor(patternImage: img).colorWithAlphaComponent(0.5)
            } else {
                self.playerBackgroundView.backgroundColor =
                    UIColor.clearColor().colorWithAlphaComponent(0.5)
            }

            self.percentLabel.setNeedsDisplay()
            self.progressingView.setNeedsDisplay()
            self.playerBackgroundView.setNeedsDisplay()
        })
    }
    
    override func viewDidLoad() {
        
        // do nothing if download is not over
        if videoDownloaded == true {
            downloadIndicator.hidden = true
            progressView.hidden = true
            progressingView.hidden = true
            percentLabel.hidden = true
            seekBar.hidden = false
        } else {
            downloadIndicator.hidden = false
            progressView.hidden = false
            progressingView.hidden = false
            percentLabel.hidden = false
            seekBar.hidden = true
            
            // get notification of video download percent from ContainerViewController class
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: "handleVideoDownloadPercentNotif:",
                name: "videoDownloadPercentNotif", object: nil)

            return
        }

        // urlからassetを生成.
        let avAsset = AVURLAsset(URL: videoUrl, options: nil)
        
        // AVPlayerに再生させるアイテムを生成.
        playerItem = AVPlayerItem(asset: avAsset)
        
        // AVPlayerを生成.
        videoPlayer = AVPlayer(playerItem: playerItem)
        
        // UIViewのレイヤーをAVPlayerLayerにする.
        let layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.player = videoPlayer
        
        // レイヤーを追加する.
        self.view.layer.addSublayer(layer)
        
        // 動画のシークバーとなるUISliderを生成
        seekBar.maximumValue = Float(CMTimeGetSeconds(avAsset.duration))
        seekBar.addTarget(self, action: "onSliderValueChange:", forControlEvents: UIControlEvents.ValueChanged)
        
        /*
        シークバーを動画とシンクロさせる為の処理.
        */
        
        // 0.5分割で動かす事が出来る様にインターバルを指定.
        let interval : Double = Double(0.5 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)

        // CMTimeに変換する.
        let time : CMTime = CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC))

        // time毎に呼び出される.
        videoPlayer.addPeriodicTimeObserverForInterval(time, queue: nil) { (time) -> Void in
            
            // 総再生時間を取得.
            let duration = CMTimeGetSeconds(self.videoPlayer.currentItem!.duration)
            
            // 現在の時間を取得.
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            
            // シークバーの位置を変更.
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
        }
        
        // 動画の再生ボタンを生成
        let startButton = UIButton(frame: CGRectMake(0, 0, 50, 50))
        startButton.layer.position = CGPointMake(self.view.bounds.midX, self.view.bounds.maxY - 100)
        startButton.layer.masksToBounds = true
        startButton.layer.cornerRadius = 20.0
        startButton.backgroundColor = UIColor.orangeColor()
        startButton.setTitle("Play", forState: UIControlState.Normal)
        startButton.addTarget(self, action: "onButtonClick:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(startButton)
    }
    
    // 再生ボタンが押された時に呼ばれるメソッド.
    func onButtonClick(sender : UIButton){
        
        // get current button rect
        let currentFrame = sender.frame
        let currentX = currentFrame.origin.x
        let currentY = currentFrame.origin.y
        let currentWidth = currentFrame.size.width
        let currentHeight = currentFrame.size.height
        
        // play or pause
        if sender.titleLabel?.text == "Play" {
            sender.setTitle("Pause", forState: UIControlState.Normal)
            sender.frame = CGRectMake(currentX - 10, currentY, currentWidth + 20, currentHeight)
            videoPlayer.play()
        } else {
            sender.setTitle("Play", forState: UIControlState.Normal)
            sender.frame = CGRectMake(currentX + 10, currentY, currentWidth - 20, currentHeight)
            videoPlayer.pause()
        }
        
        // 再生時間を最初に戻して再生.
        //videoPlayer.seekToTime(CMTimeMakeWithSeconds(0, Int32(NSEC_PER_SEC)))
    }
 
    // stop playing when view dispears
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let theVideoPlayer = videoPlayer {
            theVideoPlayer.pause()
        }
    }
    
    // シークバーの値が変わった時に呼ばれるメソッド.
    func onSliderValueChange(sender : UISlider){
        
        // 動画の再生時間をシークバーとシンクロさせる.
        videoPlayer.seekToTime(CMTimeMakeWithSeconds(Float64(seekBar.value), Int32(NSEC_PER_SEC)))
    }
}

// レイヤーをAVPlayerLayerにする為のラッパークラス.
class AVPlayerView : UIView{
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override class func layerClass() -> AnyClass{
        return AVPlayerLayer.self
    }
    
}