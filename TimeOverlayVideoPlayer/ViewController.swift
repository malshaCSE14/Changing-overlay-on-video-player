//
//  ViewController.swift
//  TimeOverlayVideoPlayer
//
//  Created by Malsha Hansini on 1/18/20.
//  Copyright © 2020 eyepax. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate , UINavigationControllerDelegate  {
    var videoAndImageReview = UIImagePickerController()
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet var overlayBackgroundView: UIView!
    var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelTime.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapWatchVideo(_ sender: Any) {
        videoAndImageReview.sourceType = .savedPhotosAlbum
        videoAndImageReview.delegate = self
        videoAndImageReview.mediaTypes = ["public.movie"]
        present(videoAndImageReview, animated: true, completion: nil)
    }
    
    @IBAction func didTapRecordVideo(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            print("Camera Available")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera UnAvaialable")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        let imagePickerVideoUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        var metadataDateValue = Date()
        
        if (info[UIImagePickerControllerReferenceURL] != nil) {
            // watch video
            if ((info[UIImagePickerControllerMediaURL] as? NSURL) != nil){
                let asset = AVAsset(url: info[UIImagePickerControllerMediaURL] as! URL)
                let formatsKey = "availableMetadataFormats"
                let dateFormatter = ISO8601DateFormatter()
                
                asset.loadValuesAsynchronously(forKeys: [formatsKey]) {
                    var error: NSError? = nil
                    let status = asset.statusOfValue(forKey: formatsKey, error: &error)
                    if status == .loaded {
                        for format in asset.availableMetadataFormats {
                            let metadata = asset.metadata(forFormat: format)
                            let metadataFilteredVal = metadata.last?.value(forKey: "value")! ?? "nill"
                            metadataDateValue = dateFormatter.date(from:metadataFilteredVal as! String)!
                        }
                    }
                }
            }
        } else {
            //record video
            guard
                let mediaType = info[UIImagePickerControllerMediaType] as? String,
                mediaType == (kUTTypeMovie as String),
                let url = info[UIImagePickerControllerMediaURL] as? URL,
                UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
                else {
                    return
            }
            UISaveVideoAtPathToSavedPhotosAlbum(
                url.path,
                self,
                #selector(video(_:didFinishSavingWithError:contextInfo:)),
                nil)
        }
        
        // define video player
        let video = AVPlayer(url: imagePickerVideoUrl! as URL)
        let videoPlayer = AVPlayerViewController()
        videoPlayer.player = video
        videoPlayer.view.frame = self.view.frame
        videoPlayer.contentOverlayView?.addSubview(overlayBackgroundView)
        
        // present video
        present(videoPlayer, animated: false, completion: {
            video.play()
        })
        
        // add time to the overlay
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        overlayBackgroundView.isHidden = false
        timeObserverToken = videoPlayer.player?.addPeriodicTimeObserver(forInterval: time, queue: .main) {
            [weak self] time in self?.changeLabel(startTime: metadataDateValue, time: time)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoDone), name: NSNotification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification"), object: videoPlayer.player?.currentItem)
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func changeLabel(startTime : Date, time: CMTime) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .second, value: Int(CMTimeGetSeconds(time)), to: startTime)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        labelTime.text = df.string(from: date!)
    }
    @objc func videoDone(){
        print("DONE")
        dismiss(animated: true, completion: nil)
    }
}

extension CMTime {
    var durationInSecnds:Int {
        return Int(CMTimeGetSeconds(self))
    }
}
