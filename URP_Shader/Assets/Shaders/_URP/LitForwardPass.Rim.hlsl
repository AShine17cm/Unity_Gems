// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_LIT_PASS_INCLUDED
#define URP_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting.hlsl"

half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    
    half rim = 1.0 - saturate(dot (inputData.normalWS, inputData.viewDirectionWS));
    surfaceData.emission = _RimColor *  pow (rim, _RimPower) * _RimIntensity;
    half4 color = URPFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, 
                                 surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    return color;
};


#endif //URP_LIT_PASS_INCLUDED