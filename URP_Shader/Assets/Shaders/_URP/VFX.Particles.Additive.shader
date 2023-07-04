Shader "_URP/VFX/Particles Additive"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
        [HDR] _BaseColor("Color", Color) = (.5, .5, .5, .5)
        [Toggle(_SOFTPARTICLES_ON)] _EnableSoftParticle("Enable Soft Particle", Float) = 0
        [ShowIfEnabled(_SOFTPARTICLES_ON)] _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 0.5
    }
    
    SubShader
    {
        Tags {  "Queue"="Transparent"  "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"  "PreviewType"="Plane"}
        Blend SrcAlpha One
        ColorMask RGB
        Cull Off Lighting Off ZWrite Off
        
        Pass
        {
            name "Particle"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            #pragma shader_feature _SOFTPARTICLES_ON

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #define FOG_LINEAR 1
            // #pragma multi_compile _ FOG_LINEAR
            #pragma multi_compile_instancing
            
            #include "VFX.Particles.Input.hlsl"

            struct Attributes
            {
                float4 positionOS               : POSITION;
                half4 color                     : COLOR;
                float2 uv                       : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS               : SV_POSITION;
                half4 color                     :COLOR;
                float2 uv                       : TEXCOORD0;
                float fogCoord                  : TEXCOORD1;
            #if defined(_SOFTPARTICLES_ON) 
                float4 projectedPosition        : TEXCOORD2;
            #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                
                output.color = input.color;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                #if defined(_SOFTPARTICLES_ON)
                    output.projectedPosition = ComputeScreenPos(output.positionCS);
                    output.projectedPosition.z = - TransformWorldToView(positionWS).z;
                #endif
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                #if defined(_SOFTPARTICLES_ON)
                float sceneZ = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, input.projectedPosition.xy/input.projectedPosition.w).r, _ZBufferParams);
                float partZ = input.projectedPosition.z;
                float fade = saturate(_InvFade * (sceneZ - partZ));
                input.color.a *= fade;
                #endif
                
                half2 uv = input.uv;
                half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor * input.color * 2.0f;
                col.a = saturate(col.a);
                col.rgb = MixFog(col.rgb, input.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
