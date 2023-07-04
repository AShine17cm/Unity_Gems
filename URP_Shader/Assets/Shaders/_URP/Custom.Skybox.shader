Shader "_URP/Custom/Sky"
{
    Properties
    {
        _Tint ("Tint Color", Color) = (.5, .5, .5, .5)
        [Gamma] _Exposure ("Exposure", Range(0, 8)) = 1.0
        _Rotation ("Rotation", Range(0, 360)) = 0
        [NoScaleOffset] _Tex ("Cubemap   (HDR)", Cube) = "grey" {}
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType" = "Background" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "PreviewType" = "Skybox"  }
        LOD 100

        Cull Off ZWrite Off

        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag
            
            //#pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            samplerCUBE _Tex;
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Tex_HDR;
            half4 _Tint;
            half _Exposure;
            float _Rotation;
            CBUFFER_END
            
            #include "ShaderLibrary/Lighting.hlsl"

            float3 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, vertex.xz), vertex.y).xzy;
            }
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float3 uv            : TEXCOORD0;
                float4 positionCS    : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                
                output.uv = input.positionOS.xyz;
                float3 rotated = RotateAroundYInDegrees(input.positionOS.xyz, _Rotation);
                float3 positionWS = TransformObjectToWorld(rotated);
                
                float4 positionCS = TransformWorldToHClip(positionWS);
                
                #if defined(UNITY_REVERSED_Z)
                // when using reversed-Z, make the Z be just a tiny
                // bit above 0.0
                positionCS.z = 1.0e-5f;
                #else
                // when not using reversed-Z, make Z/W be just a tiny
                // bit below 1.0
                positionCS.z = positionCS.w - 1.0e-5f;
                #endif
                
                output.positionCS = positionCS;
                return output;
            }

            #define unity_ColorSpaceDouble half3(4.59479380, 4.59479380, 4.59479380)
            half4 frag(Varyings input) : SV_Target
            {
                half4 tex = texCUBE (_Tex, input.uv);
                half3 c = DecodeHDREnvironment(tex, _Tex_HDR);
                c = c * _Tint.rgb * unity_ColorSpaceDouble;
                c *= _Exposure;
                return half4(c, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
