//
//  Shaders.metal
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../Common.h"

struct VertexIn {
    float3 position     [[ attribute(VertexAttributePosition) ]];
    float3 normal       [[ attribute(VertexAttributeNormal) ]];
    float2 uv           [[ attribute(VertexAttributeUV) ]];
    float3 tangent      [[ attribute(VertexAttributeTangent) ]];
    float3 bitangent    [[ attribute(VertexAttributeBitangent) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
    float3 worldTangent;
    float3 worldBitangent;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[ stage_in ]],
                             constant VertexIn *vertices [[ buffer(BufferIndexVertices) ]],
                             uint id [[ vertex_id ]],
                             constant Uniforms& uniforms [[ buffer(BufferIndexUniforms) ]]
                             ) {
    
    VertexOut out {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix
        * uniforms.modelMatrix * float4(vertex_in.position, 1),
        .worldPosition = (uniforms.modelMatrix * float4(vertex_in.position, 1)).xyz,
        .worldNormal = (uniforms.modelMatrix * float4(vertex_in.normal, 0)).xyz,
        .uv = vertex_in.uv,
        .worldTangent = (uniforms.modelMatrix * float4(vertex_in.tangent, 0)).xyz,
        .worldBitangent = (uniforms.modelMatrix * float4(vertex_in.bitangent, 0)).xyz,
    };
    return out;
}

fragment float4 fragment_main(const VertexOut vertex_out [[ stage_in ]],
                              constant ShaderMaterial& material [[ buffer(BufferIndexMaterial) ]],
                              constant Uniforms& uniforms [[ buffer(BufferIndexUniforms) ]],
                              constant ShaderLight *lights [[ buffer(BufferIndexLights) ]],
                              constant uint& lightCount [[ buffer(BufferIndexLightsCount) ]],
                              
                              texture2d<float> diffuseTexture [[ texture(TexturePositionDiffuse) ]],
                              texture2d<float> specularTexture [[ texture(TexturePositionSpecular) ]],
                              texture2d<float> occlusionTexture [[ texture(TexturePositionOcclusion) ]],
                              texture2d<float> shininessTexture [[ texture(TexturePositionShininess) ]],
                              texture2d<float> roughnessTexture [[ texture(TexturePositionRoughness) ]],
                              texture2d<float> metallicTexture [[ texture(TexturePositionMetallic) ]],
                              texture2d<float> normalTexture [[ texture(TexturePositionNormal) ]],
                              
                              sampler textureSampler [[ sampler(TexturePositionDiffuse) ]],
                              sampler normalSampler [[ sampler(TexturePositionNormal) ]]
                              ) {
    
    float2 textureUv = (material.colorTextureTransform * float3(vertex_out.uv, 1)).xy;
    float2 normalUv = (material.normalTextureTransform * float3(vertex_out.uv, 1)).xy;
#define textureOrMaterial(texture, value) is_null_texture(texture) ? material.value : texture.sample(textureSampler, textureUv).rgb
    
    float3 materialDiffuse = textureOrMaterial(diffuseTexture, diffuseColor);
    float3 materialSpecularColor = textureOrMaterial(specularTexture, specularColor);
    float3 materialOcclusion = textureOrMaterial(occlusionTexture, ambiantOcclusion).r;
    float materialShininess = textureOrMaterial(shininessTexture, shininess).r;
    float materialRoughness = textureOrMaterial(roughnessTexture, roughness).r;
    float materialMetallic = textureOrMaterial(metallicTexture, metallic).r;
    
    float3 normalValue = is_null_texture(normalTexture) ? float3(0, 0, 1) : normalTexture.sample(normalSampler, normalUv).rgb;
    normalValue = normalValue * 2 - 1;
    float3 normalDirection = float3x3(vertex_out.worldTangent,
                                      vertex_out.worldBitangent,
                                      vertex_out.worldNormal) * normalValue;
    normalDirection = normalize(normalDirection);
    
    return float4(normalDirection, 1);
    
    float3 diffuseColor = 0;
    float3 ambiantColor = 0;
    float3 specularColor = 0;
    
    for (uint i = 0; i < lightCount; i++) {
        ShaderLight light = lights[i];
        float3 lightIntensity = (1.0 - materialOcclusion) * light.intensity;
        
        if (light.type == ambiant) {
            ambiantColor += light.color * lightIntensity;
        } else if (light.type == parralel) {
            float3 lightDirection = normalize(light.direction);
            float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
            diffuseColor += lightIntensity * light.color * materialDiffuse * diffuseIntensity;
            if (diffuseIntensity > 0) {
                float3 reflection = reflect(lightDirection, normalDirection);
                float3 cameraDirection = normalize(vertex_out.worldPosition - uniforms.cameraPosition);
                float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShininess);
                specularIntensity *= materialMetallic;
                specularColor += lightIntensity * light.specularColor * materialSpecularColor * specularIntensity;
            }
        } else if (light.type == point) {
            float d = distance(light.position, vertex_out.worldPosition);
            float3 lightDirection = normalize(vertex_out.worldPosition - light.position);
            float attenuation = 1.0 / (light.attenuation.x
                                       + light.attenuation.y * d
                                       + light.attenuation.z * d * d);
            float diffuseItensity = saturate(-dot(lightDirection, normalDirection)) * materialRoughness;
            float3 color = lightIntensity * light.color * materialDiffuse * diffuseItensity;
            color *= attenuation;
            diffuseColor += color;
            if (diffuseItensity > 0) {
                float3 reflection = reflect(lightDirection, normalDirection);
                float3 cameraDirection = normalize(vertex_out.worldPosition - uniforms.cameraPosition);
                float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShininess);
                specularIntensity *= materialMetallic;
                specularColor += lightIntensity * light.specularColor * materialSpecularColor * specularIntensity;
            }
        } else if (light.type == spot) {
            float d = distance(light.position, vertex_out.worldPosition);
            float3 lightDirection = normalize(vertex_out.worldPosition - light.position);
            float3 coneDirection = normalize(light.direction);
            float spotResult = dot(lightDirection, coneDirection);
            if (spotResult > cos(light.angle)) {
                float attenuation = 1.0 / (light.attenuation.x
                                           + light.attenuation.y * d
                                           + light.attenuation.z * d * d);
                attenuation *= pow(spotResult, light.coneAttenuation);
                float diffuseIntensity = saturate(dot(-lightDirection, normalDirection));
                float3 color = lightIntensity * light.color * materialDiffuse * diffuseIntensity;
                color *= attenuation;
                diffuseColor += color;
                if (diffuseIntensity > 0) {
                    float3 reflection = reflect(lightDirection, normalDirection);
                    float3 cameraDirection = normalize(vertex_out.worldPosition - uniforms.cameraPosition);
                    float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShininess);
                    specularIntensity *= materialMetallic;
                    specularColor += lightIntensity * light.specularColor * materialSpecularColor * specularIntensity;
                }
            }
        }
        
    }
    
    float3 finalColor = diffuseColor + ambiantColor + specularColor;
    
    return float4(finalColor, 1);
}
