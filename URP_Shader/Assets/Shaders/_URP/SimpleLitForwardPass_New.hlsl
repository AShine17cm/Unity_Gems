// Most from universal@7.3.1 SimpleLitForwardPass.hlsl

#ifndef URP_SIMPLE_LIT_PASS_NEW_INCLUDED
#define URP_SIMPLE_LIT_PASS_NEW_INCLUDED

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
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};
half4 LitFrag1(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;

   //float2 pos = input.screenPos.xy/input.screenPos.w;
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
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
};
half4 LitFrag2(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;
    InitializeSurfaceData2(input.uv, surfaceData);
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
 //  float3 albedo1;
 //   if(surfaceData.emission >0.4980391f)
	//{
 //       albedo1=surfaceData.albedo;
 //   }
 //   else
 //   {
 //       albedo1=surfaceData.albedo/_addSkinColor;
 //   }
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
