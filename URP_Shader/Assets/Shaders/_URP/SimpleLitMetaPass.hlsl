#ifndef URP_SIMPLE_LIT_META_PASS_INCLUDED
#define URP_SIMPLE_LIT_META_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

struct Attributes {
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
#ifdef _TANGENT_TO_WORLD
    float4 tangentOS     : TANGENT;
#endif
};

struct Varyings {
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
};

Varyings UniversalVertexMeta(Attributes input) {
    Varyings output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2,
                                           unity_LightmapST, unity_DynamicLightmapST);
    #ifdef _CUTOFF_OR_TRANSUV                                  
    output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
    #else
    output.uv = input.uv0;
    #endif
    
    return output;
}

half4 UniversalFragmentMetaSimple(Varyings input) : SV_Target {
    float2 uv = input.uv;
    MetaInput metaInput;
#ifdef _CUTOFF_OR_TRANSUV    
    metaInput.Albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).rgb;
#else
    metaInput.Albedo = 1;
#endif    
    
#ifdef _EMISSION
    half emissionMask = 1;
    metaInput.Emission = SampleEmissionMask(uv, emissionMask);
#else
    metaInput.Emission = 0;
#endif

    metaInput.SpecularColor = SampleSpecular();
    return MetaFragment(metaInput);
}


//LWRP -> Universal Backwards Compatibility
Varyings LightweightVertexMeta(Attributes input) {
    return UniversalVertexMeta(input);
}

half4 LightweightFragmentMetaSimple(Varyings input) : SV_Target {
    return UniversalFragmentMetaSimple(input);
}

#endif
