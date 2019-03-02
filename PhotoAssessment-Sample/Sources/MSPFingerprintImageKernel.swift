//
//  MSPFingerprintImageKernel.swift
//  PhotoAssessment
//
//  Created by 杨萧玉 on 2019/2/24.
//  Copyright © 2019 杨萧玉. All rights reserved.
//

import MetalPerformanceShaders
import Metal

class MSPFingerprintImageKernel: MPSUnaryImageKernel {
    
    let computePipelineState: MTLComputePipelineState
    let threadGroupSize: MTLSize
    
    init(device: MTLDevice, computePipelineState: MTLComputePipelineState) {
        self.computePipelineState = computePipelineState
        let w = computePipelineState.threadExecutionWidth;
        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w;
        threadGroupSize = MTLSize(width: w, height: h, depth: 1);
        super.init(device: device)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fingerprintSize() -> Int {
        // HistogramBufferSize * 4.
        let bufferLength = 8192
        return bufferLength
    }
    
    func encode(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, fingerprint buffer: MTLBuffer?) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder?.pushDebugGroup("fingerprint")
        encoder?.setComputePipelineState(computePipelineState)
        encoder?.setTexture(sourceTexture, index: 0)
        encoder?.setBuffer(buffer, offset: 0, index: 0)

        if device.supportNonuniformThreadgroupSize() {
            let threadsPerGrid = MTLSize(width: sourceTexture.width, height: sourceTexture.height, depth: 1);
            encoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadGroupSize)
        }
        else {
            let w = threadGroupSize.width;
            let h = threadGroupSize.height;
            let threadgroupsPerGrid = MTLSize(width: (sourceTexture.width + w - 1) / w, height: (sourceTexture.height + h - 1) / h, depth: 1);
            encoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadGroupSize)
        }
        
        encoder?.popDebugGroup()
        encoder?.endEncoding()
    }
}
