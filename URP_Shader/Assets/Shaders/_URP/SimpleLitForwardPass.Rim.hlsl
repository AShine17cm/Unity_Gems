// Most from universal@7.3.1 SimpleLitForwardPass.hlsl

#ifndef URP_SIMPLE_LIT_PASS_INCLUDED
#define URP_SIMPLE_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Lighting.hlsl"

half4 LitFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);
    
    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;
    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);
    //specularSmoothness.a = surfaceData.smoothness;
    
    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);
    
    half rim = 1.0 - saturate(dot (inputData.normalWS, inputData.viewDirectionWS));
    surfaceData.emission += _RimColor *  pow (rim, _RimPower) * _RimIntensity;
    
    half4 color = FragmentBlinnPhong(inputData, surfaceData.albedo, specularSmoothness, specularSmoothness.a, surfaceData.emission, surfaceData.alpha);
    color.rgb *= surfaceData.occlusion;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    //color.rgb = surfaceData.albedo;
    return color;
};


#endif //URP_SIMPLE_LIT_PASS_INCLUDED