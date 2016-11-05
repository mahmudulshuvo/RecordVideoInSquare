//
//  VideoWriter.swift
//  VideoCapture
//
//  Created by SHUVO on 9/25/16.
//  Copyright © 2016 SHUVO. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoWriter : NSObject{
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    
    init(fileUrl:URL!, height:Int, width:Int, channels:Int, samples:Float64){
        fileWriter = try? AVAssetWriter(outputURL: fileUrl, fileType: AVFileTypeQuickTimeMovie)
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
            AVVideoWidthKey : width as AnyObject,
            AVVideoHeightKey : height as AnyObject
        ];
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        fileWriter.add(videoInput)
        
        let audioOutputSettings: [String: Any] = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC) as AnyObject,
            AVNumberOfChannelsKey : channels as AnyObject,
            AVSampleRateKey : samples as AnyObject,
            AVEncoderBitRateKey : 128000 as AnyObject
        ]
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = true
        fileWriter.add(audioInput)
    }
    
    func write(_ sample: CMSampleBuffer, isVideo: Bool){
        
        if CMSampleBufferDataIsReady(sample) {
            if fileWriter.status == AVAssetWriterStatus.unknown {
                print("Start writing, isVideo = \(isVideo), status = \(fileWriter.status.rawValue)")
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                fileWriter.startWriting()
                fileWriter.startSession(atSourceTime: startTime)
            }
            if fileWriter.status == AVAssetWriterStatus.failed {
                print("Error occured, isVideo = \(isVideo), status = \(fileWriter.status.rawValue), \(fileWriter.error!.localizedDescription)")
                return
            }
            if isVideo {
                if videoInput.isReadyForMoreMediaData {
                    videoInput.append(sample)
                }
            }else{
                if audioInput.isReadyForMoreMediaData {
                    audioInput.append(sample)
                }
            }
        }
    }
    
    func finish(_ callback: @escaping (Void) -> Void){
        fileWriter.finishWriting(completionHandler: callback)
    }
}
