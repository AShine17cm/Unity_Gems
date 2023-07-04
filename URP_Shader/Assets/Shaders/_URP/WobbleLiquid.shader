Shader "_URP/WobbleLiquid"
{
    Properties
    {

        _Fill("Fill",Range(-10,10)) = 0.0
        _LiquidColor("Liquid Color", Color) = (1, 1, 1, 1)
        _SurfaceColor("Top Color", Color) = (1, 1, 0, 1)
        _FoamColor("Foam Line Color", Color) = (1,1,1,1)
        _FresnelPower("Fresnel Power", Range(0, 5)) = 1
        _FresnelColor("Fresnel Color", Color) = (1, 1, 0, 1)
        [HideInInspector]_WobbleX("WobbleX", Float) = 0.0
        [HideInInspector]_WobbleZ("WobbleZ", Float) = 0.0
        _Rim("Foam Line Width", Range(0,0.1)) = 0.0
        _BaseMap("Base Map ", 2D) = "white" {}
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Zwrite On
            Cull off
            AlphaToMask On
            HLSLPROGRAM

        // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma shader_feature_local _RotateYorZ
            #include "ShaderLibrary/Lighting.hlsl"
           // #pragma multi_compile_instancing

            #pragma vertex LitVert
            #pragma fragment LitFrag
            #define UNITY_PI      3.14159265359f
            float _Fill,_WobbleX,_WobbleZ,_Rim;
            float4 _LiquidColor, _SurfaceColor, _FoamColor, _FresnelColor;
            float _FresnelPower;
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normal     : NORMAL;
                float2 uv         : TEXCOORD0;

            };

            struct Varyings {

                float4 positionCS : SV_POSITION;
                float3  normal  : NORMAL;
                float fillEdge : TEXCOORD0;
                float3 viewDir    : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            float4 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, sina, -sina, cosa);//rotate around Y
                return float4(mul(m, vertex.xz),vertex.yw).xzyw;
            }
  
            float4 RotateAroundZInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);//rotate around Z
                return float4(mul(m, vertex.yx),vertex.zw).yxzw;
            }
            Varyings LitVert(Attributes input) {
                Varyings output = (Varyings)0;

                output.positionCS = TransformObjectToHClip(input.positionOS);
                float3 positionWS = mul(unity_ObjectToWorld, input.positionOS.xyz);
    #if defined(_RotateYorZ)//rotateY
                // rotate it around XY
                float3 worldPosX = RotateAroundYInDegrees(float4(positionWS, 0), 360);
                // rotate around XZ
                float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
                // combine rotations with worldPos, based on sine wave from script
                float3 worldPosAdjusted = positionWS + (worldPosX * _WobbleX) + (worldPosZ * _WobbleZ);
                // how high up the liquid is
                output.fillEdge = worldPosAdjusted.y + _Fill;
#else
                //rotateZ
                 // rotate it around XZ
                float3 worldPosX = RotateAroundZInDegrees(float4(positionWS, 0), 360);
                // rotate around XY
                float3 worldPosY = float3 (worldPosX.z, worldPosX.y, worldPosX.x);
                float3 worldPosAdjusted = positionWS + (worldPosX * _WobbleX) + (worldPosY * _WobbleZ);
                // how high up the liquid is
                output.fillEdge = worldPosAdjusted.z + _Fill;
#endif
                output.viewDir = normalize(TransformWorldToObject(GetCameraPositionWS()) - input.positionOS.xyz);
                output.normal = input.normal;
                output.uv = input.uv;
                return output;
            }
            half4 LitFrag(Varyings input, float facing : VFACE) : SV_Target{

                float dotProduct = 1 - pow(dot(input.normal, input.viewDir), _FresnelPower);
                float4 RimResult = smoothstep(0.5, 1.0, dotProduct);
                RimResult *= _FresnelColor;
                float4 foam = (step(input.fillEdge, 0.5) - step(input.fillEdge, (0.5 - pow(_Rim,1.8))));
                float4 foamColored = foam * (_FoamColor * 0.75);
                float4 result = step(input.fillEdge, 0.5) - foam;
                float4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float4 resultColored = result * _LiquidColor * col;
                float4 finalResult = foamColored + resultColored;
                finalResult.rgb += RimResult;
                float4 topColor = _SurfaceColor * (foam + result) * col + foamColored;
                //VFACE returns positive for front facing, negative for backfacing
                return facing > 0 ? finalResult : topColor;
                // return foamColored;

            }

         ENDHLSL

        }


    }


}
