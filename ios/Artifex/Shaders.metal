//
//  Shaders.metal
//  Artifex
//
//  Created by Jesus Alejandro on 11/30/24.
//

//#include <metal_stdlib>
//using namespace metal;
//
//struct VertexIn {
//    float2 position [[attribute(0)]];
//};
//
//struct VertexOut {
//    float4 position [[position]];
//};
//
//vertex VertexOut vertex_shader(VertexIn in [[stage_in]], constant float2 *viewportSize [[buffer(1)]]) {
//    VertexOut out;
//
//    // Convert UIKit's top-left origin to Metal's bottom-left origin
//    float2 normalizedPosition = float2(in.position.x / viewportSize->x, 1.0 - (in.position.y / viewportSize->y));
//    
//    // Convert to Metal's clip space (-1 to 1)
//    out.position = float4(normalizedPosition * 2.0 - 1.0, 0.0, 1.0);
//
//    return out;
//}
//
//
//fragment float4 fragment_shader() {
//    return float4(1.0, 1.0, 1.0, 1.0); // White color
//}

#include <metal_stdlib>
using namespace metal;

// Vertex Shader
vertex float4 vertex_shader(const device float2* vertex_array [[ buffer(0) ]],
                            unsigned int vid [[ vertex_id ]],
                            constant vector_float2& viewportSize [[ buffer(1) ]]) {
    float2 position = vertex_array[vid];
    float2 scaledPosition = float2(position.x / viewportSize.x * 2.0 - 1.0,
                                   1.0 - position.y / viewportSize.y * 2.0);
    return float4(scaledPosition, 0.0, 1.0);
}

// Fragment Shader
fragment float4 fragment_shader() {
    return float4(0.0, 0.0, 0.0, 1.0); // Black color with full opacity
}
