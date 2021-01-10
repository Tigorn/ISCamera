//
//  PreviewShader.metal
//  ISCamera
//
//  Created by Igor Sorokin on 19.12.2020.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex Vertex vertexPreview(const device float4 *vertices [[ buffer(0) ]],
                            const device float2 *textureCoordinate [[ buffer(1) ]],
                            uint vid [[ vertex_id ]])
{
    Vertex outputVertex;
    outputVertex.position = vertices[vid];
    outputVertex.textureCoordinate = textureCoordinate[vid];
    return outputVertex;
}

fragment half4 fragmentPreview(Vertex vertexOutput [[ stage_in ]],
                               texture2d<half> texture [[ texture(0) ]],
                               sampler samplr [[ sampler(0) ]])
{
    return texture.sample(samplr, vertexOutput.textureCoordinate);
}
