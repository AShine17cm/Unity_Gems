Shader "_URP/Scope"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        _Scale("ZoomScale", Range(1.0,10.0)) = 2.0
        _CameraDistance("Use Camera Distance", Range(0,1)) = 0
      
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("Src", Float) = 1.0
        [HideInInspector] _DstBlend("Dst", Float) = 0.0
        [HideInInspector] _ZWrite("ZWrite", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Blend [_SrcBlend][_DstBlend]
        //ZWrite [_ZWrite]
        Cull [_Cull]
        
        HLSLINCLUDE
        #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
        #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX

        #define _CUTOFF_OR_TRANSUV 1
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half _Cutoff;
        half _Scale;
        float _CameraDistance;
        half4 _BaseColor;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #define FOG_LINEAR 1
            // #pragma multi_compile _ FOG_LINEAR
            #pragma multi_compile_instancing
            
            #include "ShaderLibrary/BaseSampling.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normal           : NORMAL;
                float3 tangent          : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float fogCoord   : TEXCOORD1;
                float4 vertex    : SV_POSITION;
                float3 viewPos   : TEXCOORD2;
                float3 normal    : NORMAL;
                float3 tangent   : TANGENT;
                float3 worldPos  : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.worldPos = TransformObjectToWorld(input.positionOS.xyz);
                output.viewPos = TransformWorldToView(output.worldPos);
                output.normal = mul(UNITY_MATRIX_IT_MV, input.normal);   //transform normal into eye space
                output.tangent = mul(UNITY_MATRIX_IT_MV, input.tangent);
                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 normal = normalize(input.normal);    //get normal of this fragment
                float3 tangent = normalize(input.tangent);  //get tangent
                float3 cameraDir = normalize(input.viewPos);
                float3 offset = cameraDir + normal;
                float3x3 mat = float3x3(
                    tangent,
                    cross(normal, tangent),
                    normal
                    );
                offset = mul(mat, offset);
                half2 uv = input.uv +(offset.xy * _Scale);
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv + float2(0.5,0.5)) * _BaseColor;
                half3 color = texColor.rgb;
                half alpha = texColor.a;
                AlphaDiscard(alpha);

                #ifdef _ALPHAPREMULTIPLY_ON
                color *= alpha;
                #endif

                color = MixFog(color, input.fogCoord);

                return half4(color, alpha);
            }
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/DepthOnly"
        UsePass "_URP/OnlyPass/UnlitMeta"

    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.ScopeShaderGUI"
}
