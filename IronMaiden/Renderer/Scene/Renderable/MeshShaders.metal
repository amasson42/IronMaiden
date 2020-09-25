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

constant float pi = 3.1415926535897932384626433832795;

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

typedef struct PBRLighting {
  float3 lightDirection;
  float3 viewDirection;
  float3 baseColor;
  float3 normal;
  float metallic;
  float roughness;
  float ambientOcclusion;
  float3 lightColor;
} PBRLighting;

float3 renderPBR(PBRLighting lighting);

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
    
//    float3 viewDirection = normalize(uniforms.cameraPosition - vertex_out.worldPosition);
//
//    // for lights
//    ShaderLight light = lights[0];
//
//    PBRLighting lighting;
//    lighting.lightDirection = light.direction;
//    lighting.viewDirection = viewDirection;
//    lighting.baseColor = materialDiffuse;
//    lighting.normal = normalDirection;
//    lighting.metallic = materialMetallic;
//    lighting.roughness = materialRoughness;
//    lighting.ambientOcclusion = materialOcclusion.r;
//    lighting.lightColor = light.color;
//
//    float3 specularOutput = renderPBR(lighting);
//
//    float nDot1 = dot(lighting.normal, lighting.lightDirection);
//    nDot1 = ((nDot1 + 1) / (1 + 1)) * (1 - 0.4) + 0.4;
//    float3 diffuseColor = light.color * materialDiffuse * nDot1 * materialOcclusion;
//    diffuseColor *= 1.0 - materialMetallic;
//
//    float4 finalColor = float4(specularOutput + diffuseColor, 1.0);
//
//    return finalColor;
    
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
            float diffuseItensity = saturate(-dot(lightDirection, normalDirection));
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

/*
PBR.metal rendering equation from Apple's LODwithFunctionSpecialization sample code is under Copyright © 2017 Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


float3 renderPBR(PBRLighting lighting) {
  // Rendering equation courtesy of Apple et al.
  float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
  float3 halfVector = normalize(lighting.lightDirection + lighting.viewDirection);
  float nDoth = max(0.001, saturate(dot(lighting.normal, halfVector)));
  float nDotv = max(0.001, saturate(dot(lighting.normal, lighting.viewDirection)));
  float hDotl = max(0.001, saturate(dot(lighting.lightDirection, halfVector)));
  
  // specular roughness
  float specularRoughness = lighting.roughness * (1.0 - lighting.metallic) + lighting.metallic;
  
  // Distribution
  float Ds;
  if (specularRoughness >= 1.0) {
    Ds = 1.0 / pi;
  }
  else {
    float roughnessSqr = specularRoughness * specularRoughness;
    float d = (nDoth * roughnessSqr - nDoth) * nDoth + 1;
    Ds = roughnessSqr / (pi * d * d);
  }
  
  // Fresnel
  float3 Cspec0 = float3(1.0);
  float fresnel = pow(clamp(1.0 - hDotl, 0.0, 1.0), 5.0);
  float3 Fs = float3(mix(float3(Cspec0), float3(1), fresnel));
  
  
  // Geometry
  float alphaG = (specularRoughness * 0.5 + 0.5) * (specularRoughness * 0.5 + 0.5);
  float a = alphaG * alphaG;
  float b1 = nDotl * nDotl;
  float b2 = nDotv * nDotv;
  float G1 = (float)(1.0 / (b1 + sqrt(a + b1 - a*b1)));
  float G2 = (float)(1.0 / (b2 + sqrt(a + b2 - a*b2)));
  float Gs = G1 * G2;
  
  float3 specularOutput = (Ds * Gs * Fs * lighting.lightColor) * (1.0 + lighting.metallic * lighting.baseColor) + lighting.metallic * lighting.lightColor * lighting.baseColor;
  specularOutput = specularOutput * lighting.ambientOcclusion;
  
  return specularOutput;
}

