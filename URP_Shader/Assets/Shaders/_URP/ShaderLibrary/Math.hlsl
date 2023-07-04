#ifndef URP_MATH_INCLUDED
#define URP_MATH_INCLUDED

// 1 = x^2 + y^2 + z^2
void DeriveNormalZ_float(float2 xy, float zSign, out float3 Normal){
    #if SHADERGRAPH_PREVIEW
        Normal = float3(0.5,0.5,1);
    #else
        float2 xy2 = xy * xy;
        float z = zSign * sqrt((1-xy2.x) - xy2.y);
        Normal = SafeNormalize(float3(xy, z));
    #endif
}
#endif // URP_MATH_INCLUDED