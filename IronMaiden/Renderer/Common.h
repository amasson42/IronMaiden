//
//  Common.h
//  IronMaiden
//
//  Created by Vistory Group on 08/09/2020.
//  Copyright © 2020 Vistory Group. All rights reserved.
//

#ifndef Common_h
#define Common_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    vector_float3 cameraPosition;
} Uniforms;

typedef NS_ENUM(NSInteger, LightType) {
    unused = 0,
    parralel = 1,
    spot = 2,
    point = 3,
    ambiant = 4
};

typedef struct {
    vector_float3 position;
    vector_float3 direction;
    
    LightType type;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    float angle;
    float coneAttenuation;
} Light;

typedef struct {
    vector_float3 diffuseColor;
    float shininess;
    vector_float3 specularColor;
    
    matrix_float3x3 diffuseTextureTransform;
    matrix_float3x3 normalTextureTransform;
} Material;

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1,
    
    BufferIndexMaterial = 0,
    BufferIndexLights = 2,
    BufferIndexLightsCount = 3
} BufferIndices;

typedef enum {
    VertexAttributePosition = 0,
    VertexAttributeNormal = 1,
    VertexAttributeUV = 2
} VertexAttribute;

typedef enum {
    TexturePositionDiffuse = 0,
    TexturePositionNormal = 1
} TexturePosition;

#endif /* Common_h */
