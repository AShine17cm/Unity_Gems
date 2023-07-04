#ifndef URP_CHANGECOLOR_INCLUDED
#define URP_CHANGECOLOR_INCLUDED

#include "Blend.hlsl"

half3 change_color(half3 albedo, half mask) {
    half3 col = albedo;
    #if defined (_COLOR_SOFTLIGHT)
        #ifdef _MASKMAP
        col = lerp(albedo, lerp(albedo, softLight(_ChangeColor.rgb, albedo), _ChangeColor.a), mask);
        #else
        col = lerp(albedo, softLight(_ChangeColor.rgb, albedo), _ChangeColor.a);
        #endif
    #endif
    return col;
}

half3 change_HairColor(half3 albedo, half mask) {
    half3 col = albedo;
#if defined (_COLOR_SOFTLIGHT)
#ifdef _MASKMAP
    col = lerp(albedo, lerp(albedo, softLight(_ChangeColor.rgb, albedo), _ChangeColor.a), mask);
#else
    col = lerp(albedo, softLightHair(_ChangeColor.rgb, albedo), _ChangeColor.a);
#endif
#endif
    return col;
}
#endif //URP_CHANGECOLOR_INCLUDED