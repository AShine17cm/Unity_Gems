#ifndef URP_VFX_INCLUDED
#define URP_VFX_INCLUDED

#include "Blend.hlsl"
#include "Mask.hlsl"
#include "ImageAdjustment.hlsl"

void UVAnim(inout half2 uv, half3 maskRGB, half3 speed, half3 amplitude, half normalScale, out half3 outNormalOffset){
    half3 sineTime  = sin(_Time.y * speed);
    half3 move = sineTime * amplitude * 0.01 * maskRGB;
    uv += move.x + move.y + move.z;
    outNormalOffset = sineTime * normalScale * maskRGB;
}

float2 GradientNoiseDir(float2 p)
{   
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float GradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(GradientNoiseDir(ip), fp);
    float d01 = dot(GradientNoiseDir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(GradientNoiseDir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(GradientNoiseDir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
}


float3 RGBSplitA(float Split, Texture2D Texture, SamplerState Sampler, float2 UV)
{
    float2 UVR = UV + float2(Split, Split);
    float2 UVG = UV + float2(Split, -Split);
    float2 UVB = UV + float2(-Split, -Split);

    float r = SAMPLE_TEXTURE2D(Texture, Sampler, UVR).a;
    float g = SAMPLE_TEXTURE2D(Texture, Sampler, UVG).a;
    float b = SAMPLE_TEXTURE2D(Texture, Sampler, UVB).a;

    return float3(r,g,b);
}

float2 panner_dir(float2 uv, float direction, float speed, float tiling, float2 offset = 0)
{
    direction = direction * 2 - 1;
    float2 dir = normalize(float2(cos(PI * direction), sin(PI * direction)));
    return  (dir * _Time.y * speed) + offset + (uv * tiling);
}

float2 panner(float2 uv, half2 direction, float speed, float tiling, float2 offset = 0)
{
    return  _Time.y * speed * direction + offset + uv * tiling;
}

float3 caustics_uv (Texture2D Texture, SamplerState Sampler, float2 uv, float speed, float scale){
    half tiling = 1/scale;
    half split = scale * .01;
    float3 texture_1 = RGBSplitA(split, Texture, Sampler, panner(uv, half2(0, 1), speed, tiling));
    float3 texture_2 = RGBSplitA(split, Texture, Sampler, panner(uv, half2(0, 1), speed, -tiling));
    return min(texture_1, texture_2);
}


half3 emissive (float2 uv,  TEXTURE2D_PARAM(emissionMap, sampler_emissionMap), out float emissionMask){
   half3 e = 0;
   emissionMask = 0;
#ifdef _EMISSION
    float4 emission = SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv);
    emissionMask = emission.b;
    half3 pulsation = 0;
    
    #ifdef _PAN
        float2 panUV = uv +  _Time.y * _PanOrPulsate.zw;
        panUV *= _PanOrPulsate.xy;
        emissionMask *= SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, panUV).a;
    #else
        float time = sin(_Time.y * _PanOrPulsate.x) * 0.5;
        float p = lerp(_PanOrPulsate.y, _PanOrPulsate.z, time );
        if(_PanOrPulsate.w > 0){
            half3 invertCol = 1 - saturate(_EmissionColor.rgb);
            pulsation = lerp(_EmissionColor.rgb, invertCol * _PanOrPulsate.w, p) * _EmissionColor.a;
        }else{
            pulsation = p * _EmissionColor.rgb * _EmissionColor.a;
        }
    #endif
        e = _EmissionColor.rgb * emissionMask * _EmissionColor.a + pulsation * emissionMask;
#endif
    return e;
}

#endif //URP_VFX_INCLUDED