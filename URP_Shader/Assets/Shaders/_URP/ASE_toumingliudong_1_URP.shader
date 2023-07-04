Shader "ASE/toumingliudong_1_URP"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "white" {}
        _BaseColor("Color", Color) = (1,1,1,1)
        _Power("Power", Range( 0 , 10)) = 0

        [NoScaleOffset]_MaskTex("MaskTex", 2D) = "white" {}
        _MaskUV("MaskUV", Vector) = (1,1,0,0)

    }

    SubShader
    {
        Tags {  "Queue"="Transparent"  "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"  "PreviewType"="Plane"}

        Blend One One
        ColorMask RGB
        Cull Off Lighting Off ZWrite Off

        Pass
        {
            Name "Particle"

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag
            #define FOG_LINEAR 1
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
          
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _MaskUV;
            half _Power;
            CBUFFER_END
            
            //#pragma multi_compile_instancing

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input) {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.uv = input.uv;

                //setting value to unused interpolator channels and avoid initialization warnings
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(positionWS);

                return output;
            }

            half4 frag(Varyings input) : SV_Target {
                UNITY_SETUP_INSTANCE_ID(input);

                half2 uv_MainTex = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                half2 uv03 = input.uv * _MaskUV.xy + _Time.y * _MaskUV.zw;

                half4 finalColor = _BaseColor * SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv_MainTex).r * _BaseColor.a
                    * _Power * SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uv03).r;
                
                return finalColor;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}