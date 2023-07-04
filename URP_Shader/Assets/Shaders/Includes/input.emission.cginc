#ifndef AURORA_INPUT_EMISSION
#define AURORA_INPUT_EMISSION

uniform sampler2D _EmissionMap; 
half4 _EmissionColor;

bool _UseNoise;

bool _PanEmission;
half4 _Pan;

bool _PulsateEmission;
half _EmissionPulsateSpeed;
half _MinPulseBrightness;


half3 Emission (float2 uv){
    float emissionMask = tex2D(_EmissionMap, uv).b;
    float pulsation = _PulsateEmission ? (_MinPulseBrightness + ( (sin(_Time.y * _EmissionPulsateSpeed) + 1.0) * (1.0 - _MinPulseBrightness) ) / 2.0) : 1.0;
    if(_UseNoise){
        if(_PanEmission){
            float2 panUV = uv + _PanEmission * _Time.y * _Pan.xy;
            panUV *= _Pan.zw;
            emissionMask *= tex2D(_EmissionMap, panUV).a;
        }else{
            emissionMask *= tex2D(_EmissionMap, uv).a;
        }
    }
    return _EmissionColor * pulsation * emissionMask;
}
#endif // AURORA_INPUT_EMISSION