//
//  MovieRecorder.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 28.11.2020.
//

import AVFoundation

class ISVideoRecorder {
    
    var file: ISFile
    var status: ISRecodingStatus = .idle
    private var callbackQueue: DispatchQueue
    private weak var delegate: ISVideoRecorderDelegate!
    
    let fileManager: FileManager = .default
    var queue: DispatchQueue = .init(label: "iscamera.isvideorecorder.queue")
    var assetWriter: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    
    var videoFormatDescription: CMFormatDescription?
    var videoTransform: CGAffineTransform = .identity
    var videoCompressionSettings: [String: Any] = [:]
    var lastVideoTimestamp: CMTime = .zero
    
    var audioFormatDescription: CMFormatDescription?
    var audioCompressionSettings: [String: Any] = [:]
    var lastAudioTimestamp: CMTime = .zero
    
    private var totalTimeOffset: CMTime = .zero
    private var timestampPaused: Bool = false
    
    init(file: ISFile, delegate: ISVideoRecorderDelegate, callbackQueue: DispatchQueue) {
        self.file = file
        self.delegate = delegate
        self.callbackQueue = callbackQueue
    }
    
    func videoSettings(formatDescription: CMFormatDescription? = nil, compressionSettings: [String: Any]? = nil) {
        queue.sync {
            if let formatDescription = formatDescription {
                self.videoFormatDescription = formatDescription
            }
            if let compressionSettings = compressionSettings {
                self.videoCompressionSettings = compressionSettings
            }
        }
    }
    
    func audioSettings(formatDescription: CMFormatDescription? = nil, compressionSettings: [String: Any]? = nil) {
        queue.sync {
            if let formatDescription = formatDescription {
                self.audioFormatDescription = formatDescription
            }
            if let compressionSettings = compressionSettings {
                self.audioCompressionSettings = compressionSettings
            }
        }
    }
    
    func addVideoTrack(
        with formatDescription: CMFormatDescription,
        transform: CGAffineTransform,
        compressionSettings: [String: Any]
    ) {
        guard status.isIdle else { return }
        
        queue.sync {
            self.videoFormatDescription = formatDescription
            self.videoTransform = transform
            self.videoCompressionSettings = compressionSettings
        }
    }
    
    func addAudioTrack(
        with formatDescription: CMFormatDescription,
        compressionSettings: [String: Any]
    ) {
        guard status.isIdle else { return }
        
        queue.sync {
            self.audioFormatDescription = formatDescription
            self.audioCompressionSettings = compressionSettings
        }
    }
    
    func prepareToRecord() {
        guard status.isIdle else { return }
        
        queue.async {
            try? self.fileManager.removeItem(at: self.file.url)
            
            do {
                self.assetWriter = try AVAssetWriter(url: self.file.url, fileType: self.file.type)
                self.setupVideoInput()
                self.setupAudioInput()
                self.assetWriter?.startWriting()
                self.transition(to: .prepared, error: nil)
            } catch {
                self.transition(to: .failed, error: error)
            }
        }
    }
    
    private func setupVideoInput() {
        guard
            let assetWriter = assetWriter,
            let formatDescription = videoFormatDescription,
            assetWriter.canApply(outputSettings: videoCompressionSettings, forMediaType: .video)
        else { return }
        
        let vInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoCompressionSettings,
            sourceFormatHint: formatDescription)
        
        vInput.expectsMediaDataInRealTime = true
        vInput.transform = self.videoTransform
        
        if assetWriter.canAdd(vInput) {
            assetWriter.add(vInput)
            videoInput = vInput
        }
    }
    
    private func setupAudioInput() {
        guard let assetWriter = assetWriter,
              let formatDescription = audioFormatDescription,
              assetWriter.canApply(outputSettings: audioCompressionSettings, forMediaType: .audio)
        else { return }
        
        let aInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioCompressionSettings,
            sourceFormatHint: formatDescription)
        
        aInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(aInput) {
            assetWriter.add(aInput)
            audioInput = aInput
        }
    }
    
    func appendVideo(pixelBuffer: CVPixelBuffer, at timestamp: CMTime) {
        guard let formatDescription = videoFormatDescription else { return }
            
        queue.async {
            var sampleBuffer: CMSampleBuffer?
            
            self.adjustTimestamp(from: timestamp)
            var timing = self.getTimingInfo(from: timestamp)
            
            CMSampleBufferCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                dataReady: true,
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: formatDescription,
                sampleTiming: &timing,
                sampleBufferOut: &sampleBuffer)
            
            self.lastVideoTimestamp = timestamp
            
            if let sampleBuffer = sampleBuffer {
                self.append(sampleBuffer: sampleBuffer, for: .video)
            }
        }
    }
    
    private func adjustTimestamp(from timestamp: CMTime) {
        if timestampPaused {
            timestampPaused.toggle()
            
            let offset = CMTimeSubtract(timestamp, lastVideoTimestamp)
            totalTimeOffset = CMTimeAdd(totalTimeOffset, offset)
        }
    }
    
    func getTimingInfo(from timestamp: CMTime) -> CMSampleTimingInfo {
        return CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTimeSubtract(timestamp, totalTimeOffset),
            decodeTimeStamp: .invalid)
    }
    
    func appendAudio(sampleBuffer: CMSampleBuffer) {
        queue.async {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.lastAudioTimestamp = timestamp
            
            if let sample = self.adjustSampleBufferTimestamp(sample: sampleBuffer, at: timestamp) {
                self.append(sampleBuffer: sample, for: .audio)
            }
        }
    }
    
    func adjustSampleBufferTimestamp(sample: CMSampleBuffer, at timestamp: CMTime) -> CMSampleBuffer? {
        var count: CMItemCount = 0
        var info: [CMSampleTimingInfo] = []
        
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
        
        for i in 0 ..< info.count {
            info[i].presentationTimeStamp = CMTimeSubtract(timestamp, totalTimeOffset)
        }
        
        var outputSample: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sample,
            sampleTimingEntryCount: count,
            sampleTimingArray: &info,
            sampleBufferOut: &outputSample)
        
        return outputSample
    }
    
    private func append(sampleBuffer: CMSampleBuffer, for mediaType: AVMediaType) {
        guard status.recordingOrPrepared else { return }
        
        if self.status.isPrepared {
            let sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter?.startSession(atSourceTime: sessionAtSourceTime)
            transition(to: .recording, error: nil)
        }
        
        let input = mediaType == .video ? videoInput : audioInput
        
        if
            status.isRecording,
            let input = input,
            input.isReadyForMoreMediaData {
            
            input.append(sampleBuffer)
        }
    }
    
    func pauseRecording() {
        guard status.isRecording else { return }
        
        queue.sync {
            self.status = .paused
            self.timestampPaused = true
        }
    }
    
    func resumeRecording() {
        guard status.isPaused else { return }
        
        queue.sync(flags: .barrier) {
            self.status = .recording
        }
    }
    
    func finishRecording() {
        guard status.isRecording else { return }
        
        queue.async {
            self.assetWriter?.inputs.forEach { $0.markAsFinished() }
            self.assetWriter?.finishWriting(completionHandler: { [weak self] in
                if let error = self?.assetWriter?.error {
                    self?.transition(to: .failed, error: error)
                } else {
                    self?.transition(to: .finished, error: nil)
                }
            })
        }
    }
    
    func transition(to newStatus: ISRecodingStatus, error: Error?) {
        guard newStatus != status else { return }
        status = newStatus
        
        callbackQueue.async {
            switch self.status {
            case .recording:
                self.delegate.videoRecorderStartRecording(self)
            case .finished:
                self.delegate.videoRecorderDidFinishRecording(self, video: self.getVideo())
            case .failed:
                guard let error = error else { break }
                self.delegate.videoRecorderDidFail(self, with: error)
            default:
                break
            }
        }
    }
    
    private func getVideo() -> ISVideo {
        guard let formatDescription = videoFormatDescription else { fatalError() }
        let codec = CMFormatDescriptionGetMediaSubType(formatDescription).toString()
        let dimension = CMVideoFormatDescriptionGetDimensions(formatDescription)
        
        return ISVideo(url: file.url, type: file.type, codec: codec, width: dimension.width, height: dimension.height, duration: assetWriter?.overallDurationHint.seconds)
    }
    
}
