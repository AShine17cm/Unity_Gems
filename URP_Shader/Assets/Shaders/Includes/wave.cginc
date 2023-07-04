#ifndef AURORA_WAVE
#define AURORA_WAVE
float2 SinWaveU(float2 uv, float time, float amplify, float freq){
    float w = freq * UNITY_PI;
    float t = UNITY_PI * time;
   // float x = sin(w * uv.y + t) * amplify *(1- uv.y);
    float x = sin(w * uv.y + t) * amplify * (0.5 - fmod(uv.y, 0.5));
    return float2(uv.x + x, uv.y);
}

float2 SinWaveV(float2 uv, float time, float amplify, float freq){
    float w = freq * UNITY_PI ;
    float t = UNITY_PI * time;
    float y = sin(w * uv.x + t) * amplify;
    return float2(uv.x, uv.y + y);
}
float2 FloatingV(float2 uv, float time){
    uv.y += sin(time) * 0.01;
    return uv;
}

float2 FlowUV (float2 uv, float2 flowVec, float time){
    float progress = frac(time);
    return uv - flowVec * progress;
}

float3 FlowUVW (float2 uv, float2 flowVec, float time){
    float progress = frac(time);
    float3 uvw;
    uvw.xy = uv - flowVec * time;
    uvw.z = 1 - abs(1 - 2 * progress);
    return uvw;
}
#endif // AURORA_WAVE