// Most from universal@7.3.1 SimpleLitForwardPass.hlsl

#ifndef URP_SIMPLE_LIT_PASS_INCLUDED
#define URP_SIMPLE_LIT_PASS_INCLUDED

#include "ShaderLibrary/DataInput.hlsl"
#include "ShaderLibrary/Lighting.hlsl"
#include "ShaderLibrary/Mask.hlsl"

#define SmoothStepDis 0.05

float WorldPostionYMask(float posY_WS, float normalY_WS) {
    float firstSS = smoothstep(_HeightBlend - _BlendDistance, _HeightBlend + _BlendDistance, posY_WS) * normalY_WS;
    float angle = 1 - _BlendAngle * 0.01;
    float secSS = smoothstep(angle - SmoothStepDis, angle + SmoothStepDis, firstSS);
    return saturate(secSS);
}

half4 LitFrag(Varyings input) : SV_Target {
    UNITY_SETUP_INSTANCE_ID(input);

    SurfaceData surfaceData;
#ifdef _TRIPLANAR
    InitializeSurfaceData_Triplanar(input.uv, input.positionWS, input.normalWS.xyz, surfaceData);
#else
    InitializeSurfaceData(input.uv, surfaceData);
#endif

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    float mask = 0;

    if (_EnableMoss > 0) {
        mask += WorldPostionYMask(inputData.positionWS.y, inputData.normalWS.y);
    }

#ifdef _VCOLOR
    mask += smoothstep(1 - input.color.r, _ValueRemap);
#endif

    mask = saturate(mask);

    half4 specularSmoothness;
    specularSmoothness.rgb = surfaceData.specular;

    if (_EnableMoss > 0) {
        surfaceData.albedo = lerp(surfaceData.albedo, surfaceData.albedo_Moss, mask);
        surfaceData.smoothness = lerp(surfaceData.smoothness, surfaceData.smoothness * _MossSmoothness, mask);
    }

    specularSmoothness.a = SampleSpecularSmoothness(surfaceData.smoothness);
    half smoothness = specularSmoothness.a;

    half4 color = FragmentBlinnPhong(inputData, surfaceData.albedo, specularSmoothness, smoothness,
                                     surfaceData.emission, surfaceData.alpha);
    color.rgb *= surfaceData.occlusion;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

#if defined(_DEBUG)
    color.rgb = mask;
#endif
    return color;
};


#endif //URP_SIMPLE_LIT_PASS_INCLUDED
