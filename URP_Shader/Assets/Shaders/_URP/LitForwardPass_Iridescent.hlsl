// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_LIT_PASS_INCLUDED
#define URP_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/IridescenceLighting.hlsl"



half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    float2 pos=input.screenPos.xy / input.screenPos.w;
    SurfaceData surfaceData;
    InitializeSurfaceDataPBR(input.uv, surfaceData);
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    half4 color=1;
    half mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv).r;
    if (mask>0)
    {
        color = URPFragmentPBRIridescence(inputData, surfaceData.iridescenceThickness, surfaceData.iridescenceEta2, surfaceData.iridescenceEta3, surfaceData.iridescenceKappa3, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
    }
    else 
    {
        color = URPFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
    }
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
   
    return color;
};


#endif //URP_LIT_PASS_INCLUDED