// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_LIT_PASS_INCLUDED
#define URP_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting_New.hlsl"


half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
    InitializeSurfaceDataPBR(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
#if defined(_ENVIRONMENTMAP)
    half4 color = URPFragmentPBR_New(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion,surfaceData.Mask, surfaceData.emission, surfaceData.alpha);
#else
    half4 color = URPFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
#endif
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};

half4 LitFrag_New(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
    InitializeSurfaceDataPBR(input.uv, surfaceData);
    SampleA(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap),surfaceData.Mask);
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    half4 color = URPFragmentPBR_Alpha(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion,surfaceData.Mask, surfaceData.emission, surfaceData.alpha);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};

#endif //URP_LIT_PASS_INCLUDED