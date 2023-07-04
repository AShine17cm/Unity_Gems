#ifndef URP_TERRAIN_LIT_PASS_INCLUDED
#define URP_TERRAIN_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting.hlsl"

void SplatmapMix(float2 uv, inout half4 splatControl,
                out half weight, out half4 mixedDiffuse, out half4 defaultSmoothness, inout half3 mixedNormal)
{
    half4 diffAlbedo[4];

    diffAlbedo[0] = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uv * _Splat0_S);
    diffAlbedo[1] = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, uv * _Splat1_S);
    defaultSmoothness = half4(diffAlbedo[0].a, diffAlbedo[1].a, 0, 0);
    defaultSmoothness *= half4(_Splat0_Smoothness, _Splat1_Smoothness, 0, 0);
    
    #ifdef TM_3_TEX
    diffAlbedo[2] = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, uv * _Splat2_S);
    defaultSmoothness.b = _Splat2_Smoothness * diffAlbedo[2].a;
    #endif
    
    #ifdef TM_4_TEX
    diffAlbedo[3] = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, uv * _Splat3_S);
    defaultSmoothness.a = _Splat3_Smoothness * diffAlbedo[3].a;
    #endif


    // Now that splatControl has changed, we can compute the final weight and normalize
    weight = dot(splatControl, 1.0h);

    mixedDiffuse = 0.0h;
    mixedDiffuse += diffAlbedo[0] * half4(splatControl.rrr, 1.0h);
    mixedDiffuse += diffAlbedo[1] * half4(splatControl.ggg, 1.0h);
    #ifdef TM_3_TEX
    mixedDiffuse += diffAlbedo[2] * half4(splatControl.bbb, 1.0h);
    #endif
    #ifdef TM_4_TEX
    mixedDiffuse += diffAlbedo[3] * half4(splatControl.aaa, 1.0h);
    #endif
    half left = saturate(1 - splatControl.r - splatControl.g - splatControl.b - splatControl.a);
    mixedDiffuse = lerp(mixedDiffuse, diffAlbedo[0], left);
    //mixedDiffuse = lerp(mixedDiffuse, 1, left);
    
    
#if defined(_NORMALMAP) 
    half3 nrm = 0.0f;
    nrm += splatControl.r * UnpackNormal(SAMPLE_TEXTURE2D(_Splat0_Normal, sampler_Splat0_Normal, uv * _Splat0_S));
    nrm += splatControl.g * UnpackNormal(SAMPLE_TEXTURE2D(_Splat1_Normal, sampler_Splat0_Normal, uv * _Splat1_S));
    // half4 n0 = SAMPLE_TEXTURE2D(_Splat0_Normal, sampler_Splat0_Normal, uv * _Splat0_S);
    // half4 n1 = SAMPLE_TEXTURE2D(_Splat1_Normal, sampler_Splat0_Normal, uv * _Splat1_S);
    // nrm += splatControl.r * (n0.rgb * 2 - 1);
    // nrm += splatControl.g * (n1.rgb * 2 - 1);
    // defaultSmoothness.r *= n0.a;
    // defaultSmoothness.g *= n1.a;
    #ifdef TM_3_TEX
    nrm += splatControl.b * UnpackNormal(SAMPLE_TEXTURE2D(_Splat2_Normal, sampler_Splat0_Normal, uv * _Splat2_S));
    // half4 n2 = SAMPLE_TEXTURE2D(_Splat2_Normal, sampler_Splat0_Normal, uv * _Splat2_S);
    // nrm += splatControl.b * (n2.rgb * 2 - 1);
    // defaultSmoothness.b *= n2.a;
    #endif
    #ifdef TM_4_TEX
    nrm += splatControl.a * UnpackNormal(SAMPLE_TEXTURE2D(_Splat3_Normal, sampler_Splat0_Normal, uv * _Splat3_S));
    // half4 n3 = SAMPLE_TEXTURE2D(_Splat3_Normal, sampler_Splat0_Normal, uv * _Splat3_S);
    // nrm += splatControl.a * (n3.rgb * 2 - 1);
    // defaultSmoothness.a *= n3.a;
    #endif
    left = saturate(1 - splatControl.r - splatControl.g - splatControl.b - splatControl.a);
    mixedNormal = lerp(nrm, SAMPLE_TEXTURE2D(_Splat0_Normal, sampler_Splat0_Normal, uv * _Splat0_S), left);
   
    //mixedNormal = normalize(nrm.xyz);
#endif
}

half4 SplatmapFragment_High(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, input.uv);

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    SplatmapMix(input.uv, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;
    half smoothness = dot(splatControl, defaultSmoothness);
    half alpha = weight;

    InputData inputData;
    InitializeInputData(input, normalTS, inputData);
    
    half4 color = 1;
    color = UniversalFragmentPBR(inputData, albedo, 0, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, 1, /* emission */ half3(0, 0, 0), alpha);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}


half4 SplatmapFragment_Medium(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, input.uv);

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    SplatmapMix(input.uv, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;
    half smoothness = dot(splatControl, defaultSmoothness);
    half alpha = weight;

    InputData inputData;
    InitializeInputData(input, normalTS, inputData);
    
    half4 color = 1;
    color = UniversalFragmentBlinnPhong(inputData, albedo, /* specular */0, smoothness, /* emission */0, alpha);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

half4 SplatmapFragment_Low(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, input.uv);

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    SplatmapMix(input.uv, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;
    half smoothness = dot(splatControl, defaultSmoothness);
    half alpha = weight;

    InputData inputData;
    InitializeInputData(input, normalTS, inputData);
    
    half4 color = 1;
    color.rgb = Lambert(inputData, albedo, /* emission */0);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif // URP_TERRAIN_LIT_PASS_INCLUDED