//
//  ViewController.swift
//  VideoCapture
//
//  Created by SHUVO on 9/25/16.
//  Copyright © 2016 SHUVO. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var btnStack: UIStackView!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var pauseResumeBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var leftConstraint = NSLayoutConstraint()
    var rightConstraint = NSLayoutConstraint()
    var bottomConstraint = NSLayoutConstraint()
    var heightConstraint = NSLayoutConstraint()
    var videoLayer = AVCaptureVideoPreviewLayer()
    
    var isRecording = false
    let cameraEngine = CameraEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.orientation = "ForTheFirstTime"
        setupConstraints()
        setupButton()
        cameraEngine.startup()
        
        videoLayer = AVCaptureVideoPreviewLayer(session: cameraEngine.captureSession)
        videoLayer.frame = self.videoView.bounds
        
        let diameter = min((videoLayer.frame.size.width), (videoLayer.frame.size.height)) * 0.8
        videoLayer.frame = CGRect(x :(self.videoView.frame.size.width - diameter)/2,
                                  y :(self.videoView.frame.size.height - diameter)/2,
                                  width :diameter, height :diameter)
        videoLayer.cornerRadius = diameter/2
        videoLayer.masksToBounds = true
        videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoView.layer.addSublayer(videoLayer)
        
        
    }
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        switch UIDevice.current.orientation{
            
        case .portrait:
            appDelegate.orientation = "Portrait"
            setupConstraints()
            
        case .portraitUpsideDown:
            appDelegate.orientation = "PortraitUpsideDown"
            
        case .landscapeLeft:
            appDelegate.orientation = "LandscapeLeft"
            setupConstraints()
            
        case .landscapeRight:
            appDelegate.orientation = "LandscapeRight"
            setupConstraints()
            
        default:
            appDelegate.orientation = "Another"
        }
        NSLog("You have moved: \(appDelegate.orientation)")
    }
    
    
    func setupConstraints() {
        
        if (appDelegate.orientation == "ForTheFirstTime") {
            
            videoView.translatesAutoresizingMaskIntoConstraints = false
            videoView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            videoView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            videoView.widthAnchor.constraint(equalToConstant: 325).isActive = true
            videoView.heightAnchor.constraint(equalToConstant: 325).isActive = true
            
            btnStack.translatesAutoresizingMaskIntoConstraints = false
            btnStack.distribution = .fillEqually
            leftConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 50)
            rightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -50)
            bottomConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -50)
            heightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 50)
            NSLayoutConstraint.activate([leftConstraint, bottomConstraint, rightConstraint, heightConstraint])
        }
            
        else if (appDelegate.orientation == "Portrait") {
            btnStack.axis = .horizontal
            NSLayoutConstraint.deactivate([leftConstraint, rightConstraint, heightConstraint])
            leftConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 50)
            rightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -50)
            heightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 50)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint])
        }
            
        else {
            btnStack.axis = .vertical
            NSLayoutConstraint.deactivate([leftConstraint, rightConstraint, heightConstraint])
            leftConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: -50)
            rightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
            heightConstraint = NSLayoutConstraint(item: btnStack, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: 200)
            NSLayoutConstraint.activate([leftConstraint, rightConstraint, heightConstraint])
        }
        
        
    }
    
    func setupButton() {
        
        startBtn.backgroundColor = UIColor.red
        startBtn.layer.masksToBounds = true
        startBtn.layer.cornerRadius = 20.0
        startBtn.addTarget(self, action: #selector(ViewController.onClickStartButton(_:)), for: .touchUpInside)
        
        stopBtn.backgroundColor = UIColor.gray
        stopBtn.layer.masksToBounds = true
        stopBtn.layer.cornerRadius = 20.0
        stopBtn.addTarget(self, action: #selector(ViewController.onClickStopButton(_:)), for: .touchUpInside)
        
        pauseResumeBtn.backgroundColor = UIColor.gray
        pauseResumeBtn.layer.masksToBounds = true
        pauseResumeBtn.layer.cornerRadius = 20.0
        pauseResumeBtn.addTarget(self, action: #selector(ViewController.onClickPauseResumeButton(_:)), for: .touchUpInside)
    }
    
    
    func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        
        layer.videoOrientation = orientation
        videoLayer.position = self.videoView.center
        // videoLayer.frame = self.videoView.bounds
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.videoLayer.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                    
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                    
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                    
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                    
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    func onClickStartButton(_ sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startBtn, color: UIColor.gray)
            changeButtonColor(stopBtn, color: UIColor.red)
        }
    }
    
    func onClickPauseResumeButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            if cameraEngine.isPaused {
                cameraEngine.resume()
                pauseResumeBtn.setTitle("pause", for: UIControlState())
                pauseResumeBtn.backgroundColor = UIColor.gray
            }else{
                cameraEngine.pause()
                pauseResumeBtn.setTitle("resume", for: UIControlState())
                pauseResumeBtn.backgroundColor = UIColor.blue
            }
        }
    }
    
    func onClickStopButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startBtn, color: UIColor.red)
            changeButtonColor(stopBtn, color: UIColor.gray)
        }
    }
    
    func changeButtonColor(_ target: UIButton, color: UIColor){
        target.backgroundColor = color
    }


}

