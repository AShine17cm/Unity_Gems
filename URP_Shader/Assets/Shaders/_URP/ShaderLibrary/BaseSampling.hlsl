#ifndef URP_BASE_SAMPLING_INCLUDED
#define URP_BASE_SAMPLING_INCLUDED

#ifdef _CUTOFF_OR_TRANSUV

half Alpha(half albedoAlpha, half4 color)
{

#if defined(_ALPHATEST_ON)
    half alpha = albedoAlpha * color.a;
    clip(alpha - _Cutoff);
    return alpha;
#endif
    return 1;
}

void AlphaDiscard(half alpha)
{
#if defined(_ALPHATEST_ON)
    clip(alpha - _Cutoff);
#endif
}


void AlphaDiscard(half2 uv)
{
    #ifdef _ALPHATEST_ON
    Alpha(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv).a, 1);
    #endif
}

#endif

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

void SampleR(float2 uv, TEXTURE2D_PARAM(_rMap, sampler_rMap), out half R){
     half4 rgba = SAMPLE_TEXTURE2D(_rMap, sampler_rMap, uv);
     R = rgba.r;
}

inline void SampleG(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half G){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     G = rgba.g;
}

inline void SampleB(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half B){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     B = rgba.b;
}

inline void SampleA(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half A){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     A = rgba.a;
}

inline void SampleRG(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half R, out half G){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     R = rgba.r;
     G = rgba.g;
}

inline void SampleGA(float2 uv, TEXTURE2D_PARAM(_gaMap, sampler_gaMap), out half G, out half A){
     half4 rgba = SAMPLE_TEXTURE2D(_gaMap, sampler_gaMap, uv);
     G = rgba.g;
     A = rgba.a;
}

inline void SampleBA(float2 uv, TEXTURE2D_PARAM(_gaMap, sampler_gaMap), out half B, out half A){
     half4 rgba = SAMPLE_TEXTURE2D(_gaMap, sampler_gaMap, uv);
     B = rgba.b;
     A = rgba.a;
}

inline void SampleGB(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half G, out half B){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     G = rgba.g;
     B = rgba.b;
}

inline void SampleRGB(float2 uv, TEXTURE2D_PARAM(_rgMap, sampler_rgMap), out half3 RGB){
     half4 rgba = SAMPLE_TEXTURE2D(_rgMap, sampler_rgMap, uv);
     RGB = rgba.rgb;
}

inline void SampleRGBA(float2 uv, TEXTURE2D_PARAM(_rgbaMap, sampler_rgbaMap), out half3 RGB, out half A){
     half4 rgba = SAMPLE_TEXTURE2D(_rgbaMap, sampler_rgbaMap, uv);
     RGB = rgba.rgb;
     A = rgba.a;
}   

void SampleGBA(float2 uv, TEXTURE2D_PARAM(_rgbaMap, sampler_rgbaMap), out half G, out half B, out half A){
     half4 rgba = SAMPLE_TEXTURE2D(_rgbaMap, sampler_rgbaMap, uv);
     G = rgba.g;
     B = rgba.b;
     A = rgba.a;
}  

void SampleRGBAsNormal(float2 uv, TEXTURE2D_PARAM(_rgbaMap, sampler_rgbaMap), out half3 normalTS, out half smoothness)
{
#if defined(_NORMALMAP)
    half4 n = SAMPLE_TEXTURE2D(_rgbaMap, sampler_rgbaMap, uv);
    normalTS = n.rgb * 2.0h - 1.0h;
    smoothness = n.a ;
#else
    normalTS = half3(0.0h, 0.0h, 1.0h);
    smoothness = 0.5;
#endif
}

half SampleSpecularSmoothness(half specularSmoothness){
    return exp2(10 * specularSmoothness + 1);
}


#endif //URP_SAMPLING_INCLUDED