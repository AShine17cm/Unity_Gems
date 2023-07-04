
// Most from universal@7.3.1 SimpleLitForwardPass.hlsl

#ifndef URP_SIMPLE_LIT_PASS_INCLUDED
#define URP_SIMPLE_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Lighting.hlsl"
half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;

    InitializeSurfaceData(input.uv, surfaceData);

    half3 matcap = 1;

#if defined(_MATCAP) & !defined(_NORMALMAP)
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif
    
    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;
    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

#if defined(_MATCAP) && defined(_NORMALMAP)
    float3 normalVS =  TransformWorldToViewDir(inputData.normalWS);
    SampleRGB(normalVS.xy * 0.5 + 0.5, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
    //matcap = inputData.normalWS;
#endif

    half4 color = FragmentBlinnPhong(inputData, surfaceData.albedo, specularSmoothness, specularSmoothness.a,
                                     surfaceData.emission, surfaceData.alpha);
    color.rgb *= surfaceData.occlusion;
    color.rgb *= matcap;
#ifdef _EMISSION
#ifdef _HairGradient
    float2 uvGradientTex = TRANSFORM_TEX(inputData.positionWS.xy, _GradientMap);
    float2 uvGradient = float2(_Gradient_U_Speed, _Gradient_V_Speed) * _Time.y + uvGradientTex;
    float4 Gradient = SAMPLE_TEXTURE2D(_GradientMap, sampler_GradientMap, uvGradient);
    float4 mask = lerp(float4(0, 0, 0, 0), float4(1, 1, 1, 1), (2 - inputData.positionWS.y / _Fill)) * _Intensity;
    mask = mask.a > 0 ? mask : 0;
    float4 finalcol = Gradient * mask;
    finalcol *= _GradientColor;
    float4 fill = step((2 - inputData.positionWS.y / _Fill), 1);
    finalcol *= fill;
    color.rgb += finalcol.rgb;
#endif 
#endif 
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};

half4 LitFragSkin(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

   
    half3 matcap = 1;

#if defined(_MATCAP) & !defined(_NORMALMAP)
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif
    
    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;
    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

#if defined(_MATCAP) && defined(_NORMALMAP)
    float3 normalVS =  TransformWorldToViewDir(inputData.normalWS);
    SampleRGB(normalVS.xy * 0.5 + 0.5, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
    //matcap = inputData.normalWS;
#endif
half4 color;
#if defined(_ENABLESKIN)

     float3 albedo1=lerp(surfaceData.albedo,surfaceData.albedo/_addSkinColor,step(surfaceData.emission,0.4980391f));
     color = FragmentBlinnPhong(inputData,albedo1, specularSmoothness, specularSmoothness.a,
                                     surfaceData.emission, surfaceData.alpha);
#else
     color = FragmentBlinnPhong(inputData,surfaceData.albedo, specularSmoothness, specularSmoothness.a,
                                     surfaceData.emission, surfaceData.alpha);
#endif
    color.rgb *= surfaceData.occlusion;
    color.rgb *= matcap;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};

#endif //URP_SIMPLE_LIT_PASS_INCLUDED
