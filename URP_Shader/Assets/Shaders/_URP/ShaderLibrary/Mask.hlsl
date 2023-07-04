#ifndef URP_MASK_INCLUDED
#define URP_MASK_INCLUDED


float IntersectionMask(float3 positionWS, float offset = 0){
        half depth = 1;
        #if defined(_REQUIRE_DEPTH_TEXTURE)  
        half4 screenPos =  ComputeScreenPos(TransformWorldToHClip(positionWS));
        half sceneDepth = SampleSceneDepth(half2(screenPos.xy / screenPos.w));
        depth = Linear01Depth(sceneDepth, _ZBufferParams) *  _ProjectionParams.z;
        depth -= screenPos.w - offset;
        #endif
        return saturate(depth);
}

float remap(float value, float low1, float high1, float low2, float high2){
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

float remap(float value, float4 valueRemap){
    return remap(value, valueRemap.x, valueRemap.y, valueRemap.z, valueRemap.w);
}

float smoothstep(float value, float4 valueRemap){
    return smoothstep(valueRemap.x, valueRemap.y, value);
}
#endif // URP_MASK_INCLUDED