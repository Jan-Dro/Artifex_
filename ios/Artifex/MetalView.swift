//
//  MetalView.swift
//  Artifex
//
//  Created by Jesus Alejandro on 11/30/24.
//

import MetalKit

class MetalView: MTKView {
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var brushTexture: MTLTexture?
    
    private var lines: [[CGPoint]] = []
    private var currentLine: [CGPoint] = []
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.device = device ?? MTLCreateSystemDefaultDevice()
        guard let device = self.device else {
            fatalError("Metal is not supported on this device.")
        }
        
        commandQueue = device.makeCommandQueue()
        setupPipeline()
        loadBrushTexture()
        
        isOpaque = true
        backgroundColor = UIColor.white // Ensure the background color is white
    }
    
    private func setupPipeline() {
        guard let device = device else {
            fatalError("Metal device is nil")
        }

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load Metal library")
        }

        guard let vertexFunction = library.makeFunction(name: "vertex_shader"),
              let fragmentFunction = library.makeFunction(name: "fragment_shader") else {
            fatalError("Failed to load vertex or fragment shader")
        }

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }

    
    private func loadBrushTexture() {
        guard let device = device else { return }
        let textureLoader = MTKTextureLoader(device: device)
        if let url = Bundle.main.url(forResource: "brush", withExtension: "png") {
            do {
                brushTexture = try textureLoader.newTexture(URL: url, options: nil)
            } catch {
                print("Failed to load brush texture: \(error)")
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = currentRenderPassDescriptor else {
                  return
              }
        
        // Set the clear color to white
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(renderPipelineState)
        
        if let brushTexture = brushTexture {
            renderEncoder.setFragmentTexture(brushTexture, index: 0)
        }
        
        var viewportSize = vector_float2(Float(drawableSize.width), Float(drawableSize.height))
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_float2>.size, index: 1)

        for line in lines {
            drawLine(line, with: renderEncoder)
        }
        drawLine(currentLine, with: renderEncoder)

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func drawLine(_ line: [CGPoint], with renderEncoder: MTLRenderCommandEncoder) {
        guard !line.isEmpty else { return }

        var vertices = line.map { point -> SIMD2<Float> in
            // Map UIKit coordinates to Metal's coordinate system
            let metalX = Float(point.x) / Float(self.bounds.width) * Float(drawableSize.width)
            let metalY = Float(point.y) / Float(self.bounds.height) * Float(drawableSize.height)
            return SIMD2<Float>(metalX, metalY)
        }

        guard let device = device else {
            print("Device is nil")
            return
        }

        guard let vertexBuffer = device.makeBuffer(bytes: &vertices,
                                                   length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
                                                   options: []) else {
            print("Failed to create vertex buffer")
            return
        }

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertices.count)
    }

    func beginLine(at point: CGPoint) {
        currentLine = [point]
        setNeedsDisplay()
    }
    
    func addPointToLine(_ point: CGPoint) {
        currentLine.append(point)
        setNeedsDisplay()
    }
    
    func endLine() {
        lines.append(currentLine)
        currentLine = []
        setNeedsDisplay()
    }
    
    func clearCanvas() {
        lines.removeAll()
        setNeedsDisplay()
    }
    
    func snapshot() -> UIImage? {
        guard let drawable = currentDrawable else { return nil }
        let texture = drawable.texture
        // Add texture-to-UIImage conversion logic here if needed
        return nil
    }
    
    func setLines(_ savedLines: [[CGPoint]]) {
        lines = savedLines
        setNeedsDisplay()
    }
}

