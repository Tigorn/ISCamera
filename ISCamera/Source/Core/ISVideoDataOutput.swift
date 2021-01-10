//
//  VideoCapture.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 15.11.2020.
//

import AVFoundation

class ISVideoDataOutput: NSObject {
    
    weak var filter: ISFilter?
    weak var renderer: ISRenderer?
    weak var delegate: ISVideoDataOutputDelegate?
    
    var videoConnection: AVCaptureConnection?
    lazy var videoOutput: AVCaptureVideoDataOutput = .init()
    lazy var videoQueue: DispatchQueue = .init(label: "iscamera.isvideodataoutput.video")
    
    var videoFormatDescription: CMFormatDescription? {
        didSet { recorder?.videoSettings(formatDescription: videoFormatDescription) }
    }
    var videoCompressionSettings: [String: Any] = [:] {
        didSet { recorder?.videoSettings(compressionSettings: videoCompressionSettings) }
    }
    
    var audioConnection: AVCaptureConnection?
    lazy var audioOutput: AVCaptureAudioDataOutput = .init()
    lazy var audioQueue: DispatchQueue = .init(label: "iscamera.isvideodataoutput.audio")
    
    var audioFormatDescription: CMFormatDescription? {
        didSet { recorder?.audioSettings(formatDescription: audioFormatDescription) }
    }
    var audioCompressionSettings: [String: Any] = [:] {
        didSet { recorder?.audioSettings(compressionSettings: audioCompressionSettings) }
    }
    
    var codec: AVVideoCodecType = .hevc
    var fileType: AVFileType = .mp4
    
    var recorder: ISVideoRecorder?
    
    var isRecording: Bool {
        recorder?.status.isRecording ?? false
    }
    
    func setupVideoOutput(for session: AVCaptureSession) {
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)
        
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = false
        videoConnection = videoOutput.connection(with: .video)
        videoCompressionSettings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: fileType) ?? [:]
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
    }
    
    func changeCameraConnection(for session: AVCaptureSession) {
        videoConnection = videoOutput.connection(with: .video)
        videoCompressionSettings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: fileType) ?? [:]
    }
    
    func setupAudioOutput(for session: AVCaptureSession) {
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            
            audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
            audioConnection = audioOutput.connection(with: .audio)
            audioCompressionSettings = audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: fileType) as? [String: Any] ?? [:]
        }
    }
    
    func startRecording(to url: URL) {
        guard !isRecording else { return }
        configureRecorder(with: url)
    }
    
    private func configureRecorder(with url: URL) {
        let file = ISFile(url: url, type: fileType)
        recorder = ISVideoRecorder(file: file, delegate: self, callbackQueue: .main)
        
        if let videoConnection = videoConnection, let videoFormatDescription = videoFormatDescription {
            recorder?.addVideoTrack(
                with: videoFormatDescription,
                transform: .transform(for: videoConnection.videoOrientation),
                compressionSettings: videoCompressionSettings)
        }
        
        if let _ = audioConnection, let audioFormatDescription = audioFormatDescription {
            recorder?.addAudioTrack(
                with: audioFormatDescription,
                compressionSettings: audioCompressionSettings)
        }

        recorder?.prepareToRecord()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        recorder?.finishRecording()
    }
    
    func pauseRecording() {
        guard isRecording else { return }
        recorder?.pauseRecording()
    }
    
    func resumeRecording() {
        guard !isRecording else { return }
        recorder?.resumeRecording()
    }
    
}

extension ISVideoDataOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        
        if connection === videoConnection {
            
            if videoFormatDescription == nil || videoFormatDescription != formatDescription {
                setup(formatDescription: formatDescription)
            } else {
                render(sampleBuffer: sampleBuffer)
            }
            
        }
        
        if connection === audioConnection {
            
            if audioFormatDescription == nil || audioFormatDescription != formatDescription {
                audioFormatDescription = formatDescription
            }
            
            if let recorder = recorder, recorder.status.recordingOrPrepared {
                recorder.appendAudio(sampleBuffer: sampleBuffer)
            }
        }
        
    }
    
    func setup(formatDescription: CMFormatDescription) {
        videoFormatDescription = formatDescription
        
        filter?.prepare(with: videoFormatDescription!, retainedBufferCountHint: 3)
        let fDescription = filter?.outputFormatDescription ?? formatDescription
        
        videoFormatDescription = fDescription
    }
    
    func render(sampleBuffer: CMSampleBuffer) {
        guard var pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if
            let filter = filter,
            let processedBuffer = filter.process(pixelBuffer: pixelBuffer) {
            
            pixelBuffer = processedBuffer
        }
        
        self.renderer?.render(pixelBuffer: pixelBuffer)
        
        if let recorder = recorder, recorder.status.recordingOrPrepared {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            recorder.appendVideo(pixelBuffer: pixelBuffer, at: timestamp)
        }
    }
    
}

extension ISVideoDataOutput: ISVideoRecorderDelegate {
    
    func videoRecorderStartRecording(_ recorder: ISVideoRecorder) {
        delegate?.videoCaptureStartRecording()
    }
    
    func videoRecorderDidFail(_ recorder: ISVideoRecorder, with error: Error) {
        self.recorder = nil
        delegate?.videoCaptureDidFail(with: error)
    }
    
    func videoRecorderDidFinishRecording(_ recorder: ISVideoRecorder, video: ISVideo) {
        self.recorder = nil
        delegate?.videoCaptureDidFinishRecording(video: video)
    }
    
}
