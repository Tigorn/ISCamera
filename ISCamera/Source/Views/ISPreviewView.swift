//
//  ISPreviewView.swift
//  ISCamera
//
//  Created by Igor Sorokin on 19.12.2020.
//

import MetalKit
import AVFoundation

class ISPreviewView: MTKView, ISRenderer {
    
    var pixelFormat: MTLPixelFormat = .bgra8Unorm
    var orientation: AVCaptureVideoOrientation = .deviceOrientation
    var isMirroring: Bool = false
    
    private var vertexCoordBuffer: MTLBuffer!
    private var textureCoordBuffer: MTLBuffer!
    private var pixelBuffer: CVPixelBuffer?
    
    private var internalBounds: CGRect!
    private var textureWidth: Int = 0
    private var textureHeight: Int = 0
    private var textureMirroring = false
    private var textureOrientation: AVCaptureVideoOrientation = .deviceOrientation
    
    private var sampler: MTLSamplerState!
    private var renderPipelineState: MTLRenderPipelineState!
    private var textureCache: CVMetalTextureCache!
    private var commandQueue: MTLCommandQueue!
    
    private let syncQueue: DispatchQueue = .init(label: "iscamera.ispreviewview.render", qos: .userInitiated, autoreleaseFrequency: .workItem)
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        configureMetal()
        createTextureCache()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        configureMetal()
        createTextureCache()
    }
    
    private func configureMetal() {
        if device == nil {
            device = MTLCreateSystemDefaultDevice()
        }
        
        framebufferOnly = false
        
        commandQueue = device!.makeCommandQueue()
        
        let library = device!.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexPreview")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentPreview")
        renderPipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        sampler = device!.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    private func createTextureCache() {
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            assertionFailure("Unable to allocate texture cache")
        }
    }
    
    override func draw(_ rect: CGRect) {
        var orientation: AVCaptureVideoOrientation = .portrait
        var isMirroring: Bool = false
        var pBuffer: CVPixelBuffer?
        
        syncQueue.sync {
            orientation = self.orientation
            isMirroring = self.isMirroring
            pBuffer = self.pixelBuffer
        }
        
        guard
            let drawable = currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor,
            let pixelBuffer = pBuffer else { return }

        guard let texture = mtlTexture(from: pixelBuffer) else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }
        
        if
            texture.width != textureWidth ||
            texture.height != textureHeight ||
            bounds != internalBounds ||
            isMirroring != textureMirroring ||
            orientation != textureOrientation {
            
            setupVertecies(orientation: orientation, width: texture.width, height: texture.height, isMirroring: isMirroring)
        }
        
        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return
        }

        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textureCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func setupVertecies(orientation: AVCaptureVideoOrientation, width: Int, height: Int, isMirroring: Bool) {
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        
        internalBounds = bounds
        textureWidth = width
        textureHeight = height
        textureMirroring = isMirroring
        textureOrientation = orientation
        
        if textureWidth > 0 && textureHeight > 0 {
            switch orientation {
            case .landscapeLeft, .landscapeRight:
                scaleX = Float(internalBounds.width / CGFloat(textureWidth))
                scaleY = Float(internalBounds.height / CGFloat(textureHeight))
                
            case .portrait, .portraitUpsideDown:
                scaleX = Float(internalBounds.width / CGFloat(textureHeight))
                scaleY = Float(internalBounds.height / CGFloat(textureWidth))
            default:
                break
            }
        }
        
        if scaleX < scaleY {
            scaleX = scaleX / scaleY
            scaleY = 1.0
        } else {
            scaleY = scaleY / scaleX
            scaleX = 1.0
        }

        if textureMirroring {
            scaleX *= -1.0
        }
        
        let vertexData: [Float] = [
            -scaleX, -scaleY, 0.0, 1.0,
            scaleX, -scaleY, 0.0, 1.0,
            -scaleX, scaleY, 0.0, 1.0,
            scaleX, scaleY, 0.0, 1.0
        ]
        
        vertexCoordBuffer = device!.makeBuffer(
            bytes: vertexData,
            length: vertexData.count * MemoryLayout<Float>.size,
            options: [])
        
        let textureCoordinate: [Float] = .textureVerticies(for: orientation)
        
        textureCoordBuffer = device?.makeBuffer(
            bytes: textureCoordinate,
            length: textureCoordinate.count * MemoryLayout<Float>.size,
            options: [])
    }
    
    private func mtlTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            pixelFormat,
            width,
            height,
            0,
            &cvTexture)
        
        if
            let oTexture = cvTexture,
            let texture = CVMetalTextureGetTexture(oTexture) {
            
            return texture
        }
        
        return nil
    }
    
    
    func render(pixelBuffer: CVPixelBuffer) {
        syncQueue.sync {
            self.pixelBuffer = pixelBuffer
        }
    }
    
    func cameraPositionChanged(to position: AVCaptureDevice.Position) {
        syncQueue.sync {
            self.isMirroring = (position == .front)
        }
    }
    
    func orientationChanged(to newOrientation: AVCaptureVideoOrientation) {
        syncQueue.sync {
            self.orientation = newOrientation
        }
    }
    
}
