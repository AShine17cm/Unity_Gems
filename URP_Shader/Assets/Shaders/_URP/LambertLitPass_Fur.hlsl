#ifndef URP_VERTEXLIT_PASS_INCLUDED
#define URP_VERTEXLIT_PASS_INCLUDED

#include "ShaderLibrary/Lighting_Fur.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings {
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    half3 normalWS : TEXCOORD2;

#if defined(_MATCAP)
    float3 normalVS                 : TEXCOORD3;
#endif

    half fogFactor : TEXCOORD4;
    float4 shadowCoord : TEXCOORD5;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitVert(Attributes input,half _FUR_OFFSET = 0) {
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    half3 direction = lerp(input.normalOS, _Gravity * _GravityStrength + input.normalOS * (1 - _GravityStrength), FUR_OFFSET);

	input.positionOS.xyz += direction * _FurLength * FUR_OFFSET;
    half3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    half4 positionCS = TransformWorldToHClip(positionWS);

#if defined(_MATCAP)
    output.normalVS = TransformWorldToViewDir(normalWS) * 0.5 + 0.5;
#endif

    output.positionCS = positionCS;
    output.normalWS = normalWS;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#else
    output.shadowCoord.xyz = positionWS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    half3 vertexLight = VertexLighting(positionWS, normalWS);
    output.fogFactor = ComputeFogFactor(positionCS.z);

    return output;
}


#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/BaseSampling.hlsl"
half4 LitFrag(Varyings input,half _FUR_OFFSET = 0) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    float2 uv = input.uv;

    half3 albedo;
    half occlusion;
    half alpha;
    SampleBaseMapOnly(uv, albedo, occlusion, alpha);

    half3 emission =0;
    
    //albedo = LerpPattern(uv, saturate(alpha * (1 - emissionMask)), albedo);
    half3 matcap = 1;
#if defined(_MATCAP)
    SampleRGB(input.normalVS.xy, TEXTURE2D_ARGS(_MatcapMap, sampler_MatcapMap), matcap);
    matcap *= 2;
#endif

    half3 bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, input.normalWS);

    half4 shadowCoord = 0;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
#endif

    half4 color = 1;

    color.rgb = Lambert(albedo, input.normalWS, shadowCoord, bakedGI, emission);
    color.rgb *= matcap;
    color.rgb = MixFog(color.rgb, input.fogFactor);

    alpha=SAMPLE_TEXTURE2D(_LayerTex, sampler_LayerTex, TRANSFORM_TEX(input.uv, _LayerTex)).r;

    alpha=step(lerp(0,_CutoffEnd,FUR_OFFSET),alpha);
    color.a=1 - FUR_OFFSET * FUR_OFFSET;
    color.a=max(0,color.a);
    color.a*=alpha;
    color=half4(color.rgb * lerp(lerp(_ShadowColor.rgb,1,FUR_OFFSET),1,_ShadowAO),color.a);
    return color;
   
}

Varyings LitVert_LayerBase(Attributes input){return LitVert(input,0);}

half4 LitFrag_LayerBase(Varyings input) : SV_Target {return LitFrag(input,0);}

#endif //URP_VERTEXLIT_PASS_INCLUDED
