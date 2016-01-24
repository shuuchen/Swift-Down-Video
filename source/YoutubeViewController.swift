//
//  YoutubeViewController.swift
//  table_template
//
//  Created by Shuchen Du on 2015/09/26.
//  Copyright (c) 2015年 Shuchen Du. All rights reserved.
//

import UIKit

class YoutubeViewController: UIViewController {

    let myCell = "cell_id"
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var configuration: NSURLSessionConfiguration!
    var session: NSURLSession!
    var url: NSURL!
    
    var selectedVideoIndex: Int!
    var apiKey = "AIzaSyDqxwQmV1UcawuR6C4hWP5iBlZY7WqqHAI"
    var videosArray: Array<Dictionary<NSObject, AnyObject>> = []
    var videoDetailsArray: Array<Dictionary<NSObject, AnyObject>> = []
    var allVideoIDs = ""
    var refreshControl: UIRefreshControl!
    var isRefreshing: Bool!
    var pageToken: String?
    var hasVideoDetail: Bool?
    
    // youtube text field
    @IBOutlet weak var yttf: UITextField!
    @IBOutlet weak var videoTable: UITableView!
    
     // perform request task
    func performGetRequest(targetURL: NSURL!, completion: (data: NSData?, HTTPStatusCode: Int, error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: targetURL)
        request.HTTPMethod = "GET"
        
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfiguration)

        let task = session.dataTaskWithRequest(request, completionHandler: {
            
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(data: data,
                    HTTPStatusCode: (response as! NSHTTPURLResponse).statusCode, error: error)
            })
        })
        task.resume()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.indicator.hidden = true
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self,
            action: "handleRefresh:",
            forControlEvents: .ValueChanged)
        videoTable.addSubview(refreshControl!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// table view extension
extension YoutubeViewController: UITableViewDelegate, UITableViewDataSource {
    
    // table refresh
    func handleRefresh(paramSender: AnyObject) {
    
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC))
    
        dispatch_after(popTime, dispatch_get_main_queue(), {
    
            self.isRefreshing = true
            self.getGeneralVideos(self.yttf.text)
            self.refreshControl!.endRefreshing()

        })
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            
        let videoCount = self.videosArray.count
        
        return videoCount
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell {
            
        let cell = self.videoTable.dequeueReusableCellWithIdentifier(myCell,
            forIndexPath: indexPath) as! MyCell
        
        if videosArray.count > videoDetailsArray.count {
            
            hasVideoDetail = false
        } else {
            
            hasVideoDetail = true
        }
        
        let videoDetails = videosArray[videosArray.count - indexPath.row - 1]
        
        cell.duration.text = ""
        
        if hasVideoDetail! {
            let details = videoDetailsArray[videosArray.count - indexPath.row - 1]

            let duration = details["duration"] as! String
            
            cell.duration.text = formatDuration(duration)
            
        }
        
        cell.vidTitleLabel.text = videoDetails["title"] as? String
            
        if let thumbnail  = videoDetails["thumbnail"] as? String {
        
            if let url = NSURL(string: thumbnail), data = NSData(contentsOfURL: url) {
                
                cell.imgView.image = UIImage(data: data)
            }
        } else {
        
            cell.imgView.image = UIImage(named: "no_image")
        }
            
        return cell
    }
    
    // cell segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let id = segue.identifier {
            switch id {
                case "seg_music":
                    
                    let nvc = segue.destinationViewController as! UINavigationController
                    let dvc = nvc.childViewControllers[0] as! MusicViewController
                    let id = self.videoTable.indexPathForCell(sender as! MyCell)!
                    
                    dvc.videoID = videosArray[videosArray.count - id.row - 1]["videoID"] as! String
                    dvc.videoNameText = videosArray[videosArray.count - id.row - 1]["title"] as? String
                    dvc.videoDuration = videoDetailsArray[videosArray.count - id.row - 1]["duration"] as! String
                
                default:
                    break
            }
        }
    }
}

// text field extension
extension YoutubeViewController: UITextFieldDelegate {
    
    // get general videos
    func getGeneralVideos(text: String) {
        
        // Form the request URL string.
        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(text)&type=video&key=\(apiKey)"

        // page token
        if let _pageToken = self.pageToken, _isRefreshing = isRefreshing where _isRefreshing {

            urlString = urlString.stringByAppendingString("&pageToken=\(_pageToken)" )
        }
            
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: urlString)
        
        // Get the results.
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            
            if HTTPStatusCode == 200 && error == nil {
                
                // Convert the JSON data to a dictionary object.
                let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>

                // Get all search result items ("items" array).
                let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                
                self.pageToken = resultsDict["nextPageToken"] as? String
                
                // remove old data
                if !self.isRefreshing {
                
                    self.videosArray.removeAll(keepCapacity: false)
                }
            
                // Loop through all search results and keep just the necessary data.
                for var i=0; i<items.count; ++i {
                    
                    let snippetDict = items[i]["snippet"] as! Dictionary<NSObject, AnyObject>
                    
                    // Create a new dictionary to store the video details.
                    var videoDetailsDict = Dictionary<NSObject, AnyObject>()
                    
                    videoDetailsDict["title"] = snippetDict["title"]
                    videoDetailsDict["thumbnail"] = ((snippetDict["thumbnails"] as! Dictionary<NSObject, AnyObject>)["default"] as! Dictionary<NSObject, AnyObject>)["url"]
                    videoDetailsDict["videoID"] = (items[i]["id"] as! Dictionary<NSObject, AnyObject>)["videoId"]
                    
                    // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                    self.videosArray.append(videoDetailsDict)
                }

                // get all video ids
                for var i = 0; i < self.videosArray.count; i++ {
                    
                    let str = self.videosArray[i]["videoID"] as! String
                    self.allVideoIDs = self.allVideoIDs.stringByAppendingString(str)
                    
                    if i != self.videosArray.count - 1 {
                    
                        self.allVideoIDs = self.allVideoIDs.stringByAppendingString(",")
                    }
                }
                
                self.getVideoDetails(self.allVideoIDs)
                
            } else {
                
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading videos: \(error)")
                
                if !self.isRefreshing {
                    
                    self.indicator.stopAnimating()
                    self.indicator.hidden = true
                }
            }
        })
        
    }
    
    // get video details
    func getVideoDetails(videoID: String) {

        // Form the request URL string.
        var urlString = "https://www.googleapis.com/youtube/v3/videos?id=\(allVideoIDs)&part=contentDetails&key=\(apiKey)"
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        // Create a NSURL object based on the above string.
        let targetURL = NSURL(string: urlString)
        
        // Get the results.
        performGetRequest(targetURL, completion: { (data, HTTPStatusCode, error) -> Void in
            
            if HTTPStatusCode == 200 && error == nil {
                
                // Convert the JSON data to a dictionary object.
                let resultsDict = (try! NSJSONSerialization.JSONObjectWithData(data!, options: [])) as! Dictionary<NSObject, AnyObject>
                
                // Get all search result items ("items" array).
                let items: Array<Dictionary<NSObject, AnyObject>> = resultsDict["items"] as! Array<Dictionary<NSObject, AnyObject>>
                
                // remove old data
                if !self.isRefreshing {
                    
                    self.videoDetailsArray.removeAll(keepCapacity: false)
                }
                
                // Loop through all search results and keep just the necessary data.
                for var i=0; i<items.count; ++i {
                    
                    let detailsDict = items[i]["contentDetails"] as! Dictionary<NSObject, AnyObject>
                    
                    // Create a new dictionary to store the video details.
                    var videoDetailsDict = Dictionary<NSObject, AnyObject>()
                    videoDetailsDict["duration"] = detailsDict["duration"]
                    videoDetailsDict["definition"] = detailsDict["definition"]
                    
                    // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                    self.videoDetailsArray.append(videoDetailsDict)
                }
                
                if !self.isRefreshing {
                
                    self.indicator.stopAnimating()
                    self.indicator.hidden = true
                }
                
                self.videoTable.reloadData()
                
            } else {
                
                print("HTTP Status Code = \(HTTPStatusCode)")
                print("Error while loading details: \(error)")
                
                if !self.isRefreshing {
                    self.indicator.stopAnimating()
                    self.indicator.hidden = true
                }
            }
        })
    }
    
    // called when return is typed
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        self.indicator.hidden = false
        self.indicator.startAnimating()
        
        self.yttf.resignFirstResponder()
        
        self.isRefreshing = false
        
        self.getGeneralVideos(textField.text)
        
        return true
    }
    
    
}