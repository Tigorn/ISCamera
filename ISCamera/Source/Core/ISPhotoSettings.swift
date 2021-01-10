//
//  ISCaptureSettings.swift
//  ISCamera
//
//  Created by Igor Sorokin on 09.01.2021.
//

import AVFoundation

struct ISPhotoSettings {
    
    enum Mode {
        case rawOnly
        case rawWithUncompressed
        case rawWithCompressed
        case uncompressedOnly
        case compressedOnly
    }
    
    var mode: Mode!
    
    var bayerRawPixel: OSType?
    var rawFile: AVFileType?
    
    var uncompressedPixel: OSType?
    
    var compressedCodec: AVVideoCodecType?
    var compressedQuality: Float?
    
    var previewPixel: OSType?
    var previewSize: CGSize?
    
    var liveCodec: AVVideoCodecType?
    var liveURL: URL?
    
    private init(mode: Mode) {
        self.mode = mode
    }
    
    static func bayerRaw(pixel: OSType, rawFile: AVFileType? = nil) -> ISPhotoSettings {
        var i = ISPhotoSettings(mode: .rawOnly)
        i.bayerRawPixel = pixel
        i.rawFile = rawFile
        return i
    }
    
    static func uncompressed(pixel: OSType) -> ISPhotoSettings {
        var i = ISPhotoSettings(mode: .uncompressedOnly)
        i.uncompressedPixel = pixel
        return i
    }
    
    static func compressed(codec: AVVideoCodecType, quality: Float = 1) -> ISPhotoSettings {
        var i = ISPhotoSettings(mode: .compressedOnly)
        i.compressedCodec = codec
        i.compressedQuality = quality
        return i
    }
    
    static func bayerRaw(
        pixel: OSType, rawFile: AVFileType? = nil,
        withCompressed codec: AVVideoCodecType, quality: Float = 1) -> ISPhotoSettings {
        
        var i = ISPhotoSettings(mode: .rawWithCompressed)
        i.bayerRawPixel = pixel
        i.rawFile = rawFile
        i.compressedCodec = codec
        i.compressedQuality = quality
        return i
    }
    
    static func bayerRaw(
        pixel: OSType, rawFile: AVFileType? = nil,
        withUncompressed uncPixel: OSType) -> ISPhotoSettings {
        
        var i = ISPhotoSettings(mode: .rawWithUncompressed)
        i.bayerRawPixel = pixel
        i.rawFile = rawFile
        i.uncompressedPixel = uncPixel
        return i
    }
    
    @discardableResult
    mutating func withPreview(pixel: OSType, size: CGSize) -> ISPhotoSettings {
        previewPixel = pixel
        previewSize = size
        return self
    }
    
    @discardableResult
    mutating func withLivePhoto(url: URL, codec: AVVideoCodecType) -> ISPhotoSettings {
        liveURL = url
        liveCodec = codec
        return self
    }
    
    
    func resolveCaptureSettings(for output: AVCapturePhotoOutput) -> AVCapturePhotoSettings {
        var photoSettings: AVCapturePhotoSettings
        
        switch mode {
        case .rawWithCompressed:
            
            let compressed = compressedFormat(for: output)
            
            if output.availableRawPhotoPixelFormatTypes.contains(bayerRawPixel!) {
                
                photoSettings = AVCapturePhotoSettings(
                    rawPixelFormatType: bayerRawPixel!,
                    processedFormat: compressed)
                
            } else {
                photoSettings = AVCapturePhotoSettings(format: compressed)
            }
            
        case .rawWithUncompressed:
            
            let uncompressed = uncompressedFormat(for: output)
            
            if output.availableRawPhotoPixelFormatTypes.contains(bayerRawPixel!) {
                
                photoSettings = AVCapturePhotoSettings(
                    rawPixelFormatType: bayerRawPixel!,
                    processedFormat: uncompressed)
                
            } else {
                photoSettings = AVCapturePhotoSettings(format: uncompressed)
            }
            
        case .compressedOnly:
            
            let compressed = compressedFormat(for: output)
            photoSettings = AVCapturePhotoSettings(format: compressed)
            
        case .uncompressedOnly:
            
            let uncompressed = uncompressedFormat(for: output)
            photoSettings = AVCapturePhotoSettings(format: uncompressed)
            
        case .rawOnly:
            
            var file: AVFileType?
            if let rawFile = rawFile, output.availableRawPhotoFileTypes.contains(rawFile) {
                file = rawFile
            }
            
            if output.availableRawPhotoPixelFormatTypes.contains(bayerRawPixel!) {
                photoSettings = AVCapturePhotoSettings(
                    rawPixelFormatType: bayerRawPixel!,
                    rawFileType: file,
                    processedFormat: nil,
                    processedFileType: nil)
            } else {
                fallthrough
            }
            
        default:
            photoSettings = AVCapturePhotoSettings()
        }
        
        photoSettings.previewPhotoFormat = previewFormat(for: photoSettings)
        
        if let liveURL = liveURL, output.availableLivePhotoVideoCodecTypes.contains(liveCodec!) {
            photoSettings.livePhotoMovieFileURL = liveURL
            photoSettings.livePhotoVideoCodecType = liveCodec!
        }
        
        return photoSettings
    }
    
    private func compressedFormat(for output: AVCapturePhotoOutput) -> [String: Any]? {
        var compressed: [String: Any]?
        if output.availablePhotoCodecTypes.contains(compressedCodec!) {
            compressed = [
                AVVideoCodecKey: compressedCodec!,
                AVVideoCompressionPropertiesKey: [
                    AVVideoQualityKey: NSNumber(value: compressedQuality ?? 1)
                ]
            ]
        }
        return compressed
    }
    
    private func uncompressedFormat(for output: AVCapturePhotoOutput) -> [String: Any]? {
        var uncompressed: [String: Any]?
        if output.availablePhotoPixelFormatTypes.contains(uncompressedPixel!) {
            uncompressed = [
                AVVideoCodecKey: compressedCodec!,
                AVVideoCompressionPropertiesKey: [
                    AVVideoQualityKey: NSNumber(value: compressedQuality ?? 1)
                ]
            ]
        }
        return uncompressed
    }
    
    private func previewFormat(for settings: AVCapturePhotoSettings) -> [String: Any]? {
        var previewFormat: [String: Any]?
        if let previewPixel = previewPixel, settings.availablePreviewPhotoPixelFormatTypes.contains(previewPixel) {
            previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixel]
            if let previewSize = previewSize {
                previewFormat?[kCVPixelBufferWidthKey as String] = previewSize.width
                previewFormat?[kCVPixelBufferHeightKey as String] = previewSize.height
            }
        }
        return previewFormat
    }
    
}
