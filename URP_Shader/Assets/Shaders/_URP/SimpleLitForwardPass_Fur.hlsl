// Most from universal@7.3.1 SimpleLitForwardPass.hlsl

#ifndef URP_SIMPLE_LIT_PASS_INCLUDED
#define URP_SIMPLE_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput_Fur.hlsl"
#include "ShaderLibrary/VFX.hlsl"
#include "ShaderLibrary/Lighting_Fur.hlsl"


half4 LitFrag(Varyings input,half _FUR_OFFSET = 0) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);
    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData);

    
    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;
    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);


    half4 color = FragmentBlinnPhong(inputData, surfaceData.albedo, specularSmoothness, specularSmoothness.a,
                                     surfaceData.emission, surfaceData.alpha);
    color.rgb *= surfaceData.occlusion;
    
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    half alpha=SAMPLE_TEXTURE2D(_LayerTex, sampler_LayerTex, TRANSFORM_TEX(input.uv, _LayerTex)).r;

    alpha=step(lerp(0,_CutoffEnd,FUR_OFFSET),alpha);
    color.a=1 - FUR_OFFSET * FUR_OFFSET;
    color.a+=dot(inputData.viewDirectionWS,inputData.normalWS)-_EdgeFade;
    clip(color.a);
    color.a=max(0,color.a);
    color.a*=alpha;
    color=half4(color.rgb * lerp(lerp(_ShadowColor.rgb,1,FUR_OFFSET),1,_ShadowAO),color.a);
    return color;
};

Varyings LitVert_LayerBase(Attributes input){return LitVert(input,0);}

half4 LitFrag_LayerBase(Varyings input) : SV_Target {return LitFrag(input,0);}

#endif //URP_SIMPLE_LIT_PASS_INCLUDED
