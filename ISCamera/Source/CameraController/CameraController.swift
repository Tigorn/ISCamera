//
//  CamController.swift
//  PhotoTest
//
//  Created by Igor Sorokin on 05.12.2020.
//

import UIKit
import AVFoundation

class CameraController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    weak var captureControl: ISCaptureControl!
    weak var previewView: ISPreviewView!
    weak var settingsControl: ISSettingsControl!
    
    weak var snapshot: UIView?
    weak var blurView: UIView?
    weak var controls: ControlsView?
    weak var tintLabel: UILabel!
    
    var camera: ISCameraManager!
    let filter: ISSepiaFilter = .init()
    let photoProcessor: ISStillPhotoProcessor = .init()
    
    var focusRecognizer: UITapGestureRecognizer!
    var exposureRecognizer: ExposureGestureRecognizer!
    
    var isFront: Bool = false
    var isRecording: Bool = false
    var lightMode: LightMode = .auto
    
    var cameraDevice: AVCaptureDevice? {
        let device = ISCameraManager.device(
            preferredType: nil,
            mediaType: .video,
            position: isFront ? .front : .back)
        isFront.toggle()
        return device
    }
    
    override func loadView() {
        let view = CameraView()
        self.view = view
        previewView = view.previewView
        captureControl = view.captureControl
        settingsControl = view.settingsControl
        tintLabel = view.tintLabel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViews()
        setupCamera()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        previewView.orientationChanged(to: .deviceOrientation)
    }
    
    func configureViews() {
        focusRecognizer = UITapGestureRecognizer(target: self, action: #selector(previewTapped(_:)))
        exposureRecognizer = ExposureGestureRecognizer(target: self, action: #selector(previewPanned(_:)))
        focusRecognizer.require(toFail: exposureRecognizer)

        previewView.addGestureRecognizer(focusRecognizer)
        previewView.addGestureRecognizer(exposureRecognizer)
        
        captureControl.photoTapped = photoTapped(_:)
        captureControl.videoTapped = videoTapped(_:)
        
        settingsControl.lightMode.setImage(lightMode.image, for: .normal)
        settingsControl.lightMode.addTarget(self, action: #selector(lightTapped(_:)), for: .touchUpInside)
        settingsControl.changeCamera.addTarget(self, action: #selector(changeCameraTapped(_:)), for: .touchUpInside)
        
        UIView.animate(
            withDuration: 1,
            delay: 0,
            options: [.repeat, .autoreverse],
            animations: {
                self.tintLabel.alpha = 0
            },
            completion: nil)
    }
 
    func setupCamera() {
        let vDevice = cameraDevice
        let aDevice = AVCaptureDevice.default(for: .audio)
        
        photoProcessor.filter = filter
        photoProcessor.delegate = self
        
        camera = ISCameraManager(configurator: {
            $0.session.sessionPreset = .hd1280x720
            $0.setupVideoDevice(vDevice!)
            $0.setupAudioDevice(aDevice!)
            $0.previewView = previewView
            $0.filter = filter
            $0.videoOutput.delegate = self
        })
        
        camera.startSession()
    }
    
    @objc private func previewTapped(_ recognizer: UITapGestureRecognizer) {
        let previewFrame = previewView.frame
        let touchPoint = recognizer.location(in: view)
        let focusPoint = CGPoint(x: touchPoint.x / previewFrame.width, y: touchPoint.y / previewFrame.height)
        try? camera.videoDevice.focus(focusMode: .autoFocus, at: focusPoint)
        try? camera.videoDevice.exposure(exposureMode: .locked, targetBias: 0)
        
        exposureRecognizer.resetExposure()
        exposureRecognizer.configure(
            controlSize: controls?.frame.size ?? .zero,
            minExposure: camera.minExposure,
            maxExposure: camera.maxExposure)
        
        controls?.remove()
        controls = ControlsView.showControls(on: view, at: touchPoint)
    }
    
    @objc private func previewPanned(_ recognizer: ExposureGestureRecognizer) {
        guard let controls = controls else { return }
        switch recognizer.state {
        case .began:
            controls.invalidateControlsWorkitem()
        
        case .changed:
            controls.setExposureY(factor: recognizer.translationRatio)
            try? camera.videoDevice.exposure(exposureMode: .locked, targetBias: recognizer.exposure)
            
        case .ended:
            controls.startControlsWorkitem()
            
        default:
            break
        }
    }
    
    func photoTapped(_ sender: ISCaptureControl) {
        camera.capturePhoto(processor: photoProcessor)
        hideTint()
    }
    
    func videoTapped(_ sender: ISCaptureControl) {
        if isRecording {
            camera.stopRecording()
            try? camera.videoDevice.tourch(.off)
        } else {
            camera.startRecording(to: .generateVideoURl)
            try? camera.videoDevice.tourch(lightMode.torch)
        }
        
        isRecording.toggle()
        hideTint()
    }
    
    @objc func changeCameraTapped(_ sender: UIButton) {
        showBlur()
        camera.changeVideoDevice(cameraDevice!, completion: { [weak self] _ in
            guard let self = self else { return }
            self.hideBlur()
            self.updateUI()
            
            if self.isRecording {
                try? self.camera.videoDevice.tourch(self.lightMode.torch)
            }
        })
    }
    
    func showBlur() {
        blurView = previewView.showBlurSnapshot()
    }
    
    func hideBlur() {
        blurView?.removeFadeIn()
    }
    
    func hideTint() {
        tintLabel.isHidden = true
        tintLabel.layer.removeAllAnimations()
    }
    
    @objc func lightTapped(_ sender: UIButton) {
        lightMode = lightMode.nextMode()
        settingsControl.lightMode.setImage(lightMode.image, for: .normal)
        
        camera.photoOutput.flashMode = lightMode.flash
        
        if isRecording {
            try? camera.videoDevice.tourch(lightMode.torch)
        }
    }
    
    func updateUI() {
        settingsControl.lightMode.isEnabled = camera.isTorchAvailable
    }
    
}

extension CameraController: ISVideoDataOutputDelegate {
    
    func videoCaptureDidFinishRecording(video: ISVideo) {
        MediaManager.saveVideo(fileURl: video.url) { (success, error) in
            print(success ? "Media saved" : "Saving error \(error)")
        }
    }
    
}

extension CameraController: ISPhotoProcessorDelegate {
    
    func photoProcessor(_ processor: ISPhotoProcessor, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        previewView.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.previewView.alpha = 1
        }
    }
    
    func photoProcessor(_ processor: ISPhotoProcessor, didFinishProcessingPhoto photo: ISPhoto?, error: Error?) {
        guard let photo = photo else {
            print("Processor cant process photo, error \(error)")
            return
        }
        
        let context = CIContext()
        let cgImage = context.createCGImage(photo.image, from: photo.image.extent)
        let image = UIImage(cgImage: cgImage!)
        let data = image.jpegData(compressionQuality: 1)!
        
        MediaManager.saveStillPhoto(data) { (success, error) in
            print(success ? "Media saved" : "Saving error \(error)")
        }
    }
    
}
