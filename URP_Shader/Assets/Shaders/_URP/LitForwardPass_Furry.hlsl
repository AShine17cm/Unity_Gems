// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_LIT_PASS_INCLUDED
#define URP_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput_Furry.hlsl"
#include "ShaderLibrary/Lighting_Fur.hlsl"


half4 LitFrag(Varyings input,half _FUR_OFFSET = 0) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
    InitializeSurfaceDataPBR(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = UniversalFragmentPBR_Fabric(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    half2 UVnoise = input.uv.xy* _LayerTex_ST.xy * _NoiseScale + _LayerTex_ST.zw;
    half alpha =SAMPLE_TEXTURE2D(_LayerTex, sampler_LayerTex, UVnoise).r;
     alpha=step(lerp(0,_CutoffEnd,FUR_OFFSET), alpha);
   
    color.a= clamp(alpha - FUR_OFFSET * FUR_OFFSET,0,1);
    color.a+=dot(inputData.viewDirectionWS,inputData.normalWS)-_EdgeFade;
    clip(color.a );
    color.a=max(0,color.a);
    color.a*=alpha;
  
    color=half4(color.rgb * lerp(lerp(_ShadowColor.rgb,1,FUR_OFFSET),1,_ShadowAO),color.a);
    return color;

};

Varyings LitVert_LayerBase(Attributes input){return LitVert(input,0);}

half4 LitFrag_LayerBase(Varyings input) : SV_Target {return LitFrag(input,0);}


#endif //URP_LIT_PASS_INCLUDED