#ifndef URP_GLASS_FORWARD_PASS_INCLUDED
#define URP_GLASS_FORWARD_PASS_INCLUDED

#include "ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS               : SV_POSITION;
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)  || defined(_NEED_POS_WS)
    float3 positionWS               : TEXCOORD2;
#endif

#if defined (_NORMALMAP)
    float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    float3 normalWS                 : TEXCOORD3;
    float3 viewDirWS                : TEXCOORD4;
#endif

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

    half4 scrPos                    : TEXCOORD8;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitVert(Attributes input) {
    Varyings output = (Varyings)0;
    
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
   
    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

#if defined (_NORMALMAP)
    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
    output.viewDirWS = viewDirWS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)  || defined(_NEED_POS_WS)
    output.positionWS = vertexInput.positionWS;

#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;
    output.scrPos = ComputeScreenPos(vertexInput.positionCS);
    
    return output;
}

#include "ShaderLibrary/InputData.hlsl"

half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);
    
    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;
    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);
    
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    
    half3 refrCol = 0;
    #if defined(_OPAQUETEX)
    float2 uvOffset = surfaceData.normalTS.xy * _Distortion * _CameraOpaqueTexture_TexelSize.xy;
    SampleRGB((input.scrPos.xy + uvOffset)/input.scrPos.w, _CameraOpaqueTexture, sampler_CameraOpaqueTexture_linear_clamp, refrCol);
    #endif
    
    float3 reflectionDirWS = reflect(-inputData.viewDirectionWS, inputData.normalWS);
    half3 reflCol =  SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, reflectionDirWS).rgb * surfaceData.albedo * _BaseColor.rgb;
    
    #if defined(_OPAQUETEX)
    surfaceData.albedo = lerp(reflCol, refrCol,  _RefractAmount); 
    #else
    surfaceData.albedo = reflCol;
    #endif
    half4 color = 1;
    //color = FragmentBlinnPhong(inputData, surfaceData.albedo, specularSmoothness, specularSmoothness.a, surfaceData.emission, surfaceData.alpha);
    color.rgb = surfaceData.albedo;
    color.a = surfaceData.alpha * _BaseColor.a;
    color.rgb *= surfaceData.occlusion;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};


#endif //URP_GLASS_FORWARD_PASS_INCLUDED