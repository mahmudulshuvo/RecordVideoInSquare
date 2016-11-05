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
    
    var startButton, stopButton, pauseResumeButton : UIButton!
    var isRecording = false
    let cameraEngine = CameraEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        cameraEngine.startup()
        
        let videoView = UIView()
        videoView.frame = CGRect(x: 0, y: 50, width: self.view
            .frame.size.width, height: self.view.frame.size.width)
        videoView.backgroundColor = UIColor.black
        self.view.addSubview(videoView)
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: cameraEngine.captureSession)
        videoLayer?.frame = CGRect(x: 0, y: 0, width: 350, height: 350)
        let diameter = min((videoLayer?.frame.size.width)!, (videoLayer?.frame.size.height)!) * 0.8
        videoLayer?.frame = CGRect(x :(self.view.frame.size.width - diameter)/2,
                                   y :(self.view.frame.size.width - diameter)/2,
                                   width :diameter, height :diameter);
        videoLayer?.cornerRadius = diameter / 2
        videoLayer?.masksToBounds = true
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        videoView.layer.addSublayer(videoLayer!)
        
        let previewLayerConnection = videoLayer?.connection
        previewLayerConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        
        setupButton()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UInt(Int(UIInterfaceOrientationMask.portrait.rawValue)))
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    func setupButton() {
        
        startButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        startButton.backgroundColor = UIColor.red
        startButton.layer.masksToBounds = true
        startButton.setTitle("start", for: UIControlState())
        startButton.layer.cornerRadius = 20.0
        startButton.layer.position = CGPoint(x: view.bounds.width/5, y:view.bounds.height-50)
        startButton.addTarget(self, action: #selector(ViewController.onClickStartButton(_:)), for: .touchUpInside)
        
        stopButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        stopButton.backgroundColor = UIColor.gray
        stopButton.layer.masksToBounds = true
        stopButton.setTitle("stop", for: UIControlState())
        stopButton.layer.cornerRadius = 20.0
        stopButton.layer.position = CGPoint(x: view.bounds.width/5 * 2, y:view.bounds.height-50)
        stopButton.addTarget(self, action: #selector(ViewController.onClickStopButton(_:)), for: .touchUpInside)
        
        pauseResumeButton = UIButton(frame: CGRect(x: 0,y: 0,width: 60,height: 50))
        pauseResumeButton.backgroundColor = UIColor.gray
        pauseResumeButton.layer.masksToBounds = true
        pauseResumeButton.setTitle("pause", for: UIControlState())
        pauseResumeButton.layer.cornerRadius = 20.0
        pauseResumeButton.layer.position = CGPoint(x: view.bounds.width/5 * 3, y:view.bounds.height-50)
        pauseResumeButton.addTarget(self, action: #selector(ViewController.onClickPauseButton(_:)), for: .touchUpInside)
        
        view.addSubview(startButton)
        view.addSubview(stopButton);
        view.addSubview(pauseResumeButton);
    }
    
    func onClickStartButton(_ sender: UIButton){
        if !cameraEngine.isCapturing {
            cameraEngine.start()
            changeButtonColor(startButton, color: UIColor.gray)
            changeButtonColor(stopButton, color: UIColor.red)
        }
    }
    
    func onClickPauseButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            if cameraEngine.isPaused {
                cameraEngine.resume()
                pauseResumeButton.setTitle("pause", for: UIControlState())
                pauseResumeButton.backgroundColor = UIColor.gray
            }else{
                cameraEngine.pause()
                pauseResumeButton.setTitle("resume", for: UIControlState())
                pauseResumeButton.backgroundColor = UIColor.blue
            }
        }
    }
    
    func onClickStopButton(_ sender: UIButton){
        if cameraEngine.isCapturing {
            cameraEngine.stop()
            changeButtonColor(startButton, color: UIColor.red)
            changeButtonColor(stopButton, color: UIColor.gray)
        }
    }
    
    func changeButtonColor(_ target: UIButton, color: UIColor){
        target.backgroundColor = color
    }

}

