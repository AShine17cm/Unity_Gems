#ifndef UNITY_SAMPLENORMAL
#define UNITY_SAMPLENORMAL
uniform sampler2D _BumpMap;

inline void SampleNormal(float2 uv, out float3 normalLocal, out half metallic, out half roughness){
    half4 normalColor = tex2D(_BumpMap, uv);
    normalLocal = float3(normalColor.rg, 1) * 2 - 1; 
    metallic = normalColor.b;
    roughness = normalColor.a;
    
}
#endif // UNITY_SAMPLENORMAL