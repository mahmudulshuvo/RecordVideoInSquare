//
//  CameraEngine.swift
//  VideoCapture
//
//  Created by SHUVO on 9/25/16.
//  Copyright © 2016 SHUVO. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary
import Photos

class CameraEngine : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{

    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    var videoWriter : VideoWriter?

    var height:Int?
    var width:Int?
    
    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    var fileIndex = 0
    
    var timeOffset = CMTimeMake(0, 0)
    var lastAudioPts: CMTime?

    let lockQueue = DispatchQueue(label: "lockQueue", attributes: [])
    let recordingQueue = DispatchQueue(label: "recordingQueue", attributes: [])

    func startup(){
        // video input
        videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        
      
        do
        {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice) as AVCaptureDeviceInput
            captureSession.addInput(videoInput)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }

        do
        {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice) as AVCaptureDeviceInput
            captureSession.addInput(audioInput)
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        
        
        // video output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        ]
        captureSession.addOutput(videoDataOutput)
        
        height = videoDataOutput.videoSettings["Height"] as! Int!
        width = videoDataOutput.videoSettings["Width"] as! Int!
        
        // audio output
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: recordingQueue)
        captureSession.addOutput(audioDataOutput)
        
        captureSession.startRunning()
    }
    
    func shutdown(){
        captureSession.stopRunning()
    }

    func start(){
        lockQueue.sync {
            if !self.isCapturing{
                print("in")
                self.isPaused = false
                self.isDiscontinue = false
                self.isCapturing = true
                self.timeOffset = CMTimeMake(0, 0)
            }
        }
    }
    
    func stop(){
        self.lockQueue.sync {
            if self.isCapturing{
                self.isCapturing = false
                DispatchQueue.main.async(execute: { () -> Void in
                    print("in")
                    self.videoWriter!.finish { () -> Void in
                        print("Recording finished.")
                        self.videoWriter = nil
//                        let assetsLib = ALAssetsLibrary()
//                        assetsLib.writeVideoAtPath(toSavedPhotosAlbum: self.filePathUrl(), completionBlock: {
//                            (nsurl, error) -> Void in
//                            print("Transfer video to library finished.")
//                            self.fileIndex += 1
//                        })
                        
                        PHPhotoLibrary.requestAuthorization
                            { (status) -> Void in
                                switch (status)
                                {
                                case .authorized:
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.filePathUrl())
                                    }) { saved, error in
                                        if saved {
                                            print("Video saved successfully")
                                        } else{
                                            print("video erro: \(error)")
                                            
                                        }
                                    }
                                case .denied:
                                    print("User denied")
                                default:
                                    print("Restricted")
                                }
                        }
                        
                    }
                })
            }
        }
    }
    
    func pause(){
        self.lockQueue.sync {
            if self.isCapturing{
                print("in")
                self.isPaused = true
                self.isDiscontinue = true
            }
        }
    }
    
    func resume(){
        self.lockQueue.sync {
            if self.isCapturing{
                print("in")
                self.isPaused = false
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!){
        self.lockQueue.sync {
            if !self.isCapturing || self.isPaused {
                return
            }
            
            let isVideo = captureOutput is AVCaptureVideoDataOutput
            
            var videoConnection:AVCaptureConnection?
            for connection in captureOutput.connections {
                
                for port in (connection as AnyObject).inputPorts! {
                    
                    if (port as AnyObject).mediaType == AVMediaTypeVideo {
                        
                        videoConnection = connection as? AVCaptureConnection
                        
                        if videoConnection!.isVideoMirroringSupported {
                          //  videoConnection!.isVideoMirrored = true
                            videoConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
                        }
                    }
                }
            }
            
            if self.videoWriter == nil && !isVideo {
                let fileManager = FileManager()
                if fileManager.fileExists(atPath: self.filePath()) {
                    do {
                        try fileManager.removeItem(atPath: self.filePath())
                    } catch _ {
                    }
                }
                
                let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
                
                print("setup video writer")
                self.videoWriter = VideoWriter(
                    fileUrl: self.filePathUrl(),
                    height:350, width:350,
                    channels: Int((asbd?.pointee.mChannelsPerFrame)!),
                    samples: (asbd?.pointee.mSampleRate)!
                )
            }
            
            if self.isDiscontinue {
                if isVideo {
                    return
                }

                var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let isAudioPtsValid = self.lastAudioPts!.flags.intersection(CMTimeFlags.valid)
                if isAudioPtsValid.rawValue != 0 {
                    print("isAudioPtsValid is valid")
                    let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(CMTimeFlags.valid)
                    if isTimeOffsetPtsValid.rawValue != 0 {
                        print("isTimeOffsetPtsValid is valid")
                        pts = CMTimeSubtract(pts, self.timeOffset);
                    }
                    let offset = CMTimeSubtract(pts, self.lastAudioPts!);

                    if (self.timeOffset.value == 0)
                    {
                        print("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = offset;
                    }
                    else
                    {
                        print("timeOffset is \(self.timeOffset.value)")
                        self.timeOffset = CMTimeAdd(self.timeOffset, offset);
                    }
                }
                self.lastAudioPts!.flags = CMTimeFlags()
                self.isDiscontinue = false
            }
            
            var buffer = sampleBuffer
            if self.timeOffset.value > 0 {
                buffer = self.ajustTimeStamp(sampleBuffer, offset: self.timeOffset)
            }

            if !isVideo {
                var pts = CMSampleBufferGetPresentationTimeStamp(buffer!)
                let dur = CMSampleBufferGetDuration(buffer!)
                if (dur.value > 0)
                {
                    pts = CMTimeAdd(pts, dur)
                }
                self.lastAudioPts = pts
            }
            
            self.videoWriter?.write(buffer!, isVideo: isVideo)
        }
    }
    
    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }
    
    func ajustTimeStamp(_ sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(0, 0), presentationTimeStamp: CMTimeMake(0, 0), decodeTimeStamp: CMTimeMake(0, 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);

        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }

        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
}
