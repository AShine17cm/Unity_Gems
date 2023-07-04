Shader "_URP/SelfDepthPass2"
{

    SubShader
    {
        LOD 100
		
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            //ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma vertex DepthOnlyVertexSelf
            #pragma fragment DepthOnlyFragmentSelf

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            // #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
			#pragma shader_feature _DEPTH_DUALCHANNEL_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
			#include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"

			struct VaryingsLeanSelf
			{
				float4 clipPos      : SV_POSITION;
			#ifdef _ALPHATEST_ON
				float2 texcoord     : TEXCOORD0;
			#endif
				float4 scrPos     : TEXCOORD1;
				float3 viewPos     : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			VaryingsLeanSelf DepthOnlyVertexSelf(AttributesLean v)
			{
				VaryingsLeanSelf o = (VaryingsLeanSelf)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TerrainInstancing(v.position, v.normalOS);
				o.clipPos = TransformObjectToHClip(v.position.xyz);

				float3 wpos = TransformObjectToWorld(v.position.xyz);
				//float3 vpos = TransformWorldToView(wpos);
				o.scrPos = ComputeScreenPos(o.clipPos);

				o.viewPos = TransformWorldToView(wpos);
				//o.viewPos = o.clipPos.xyz/ o.clipPos.w;
			#ifdef _ALPHATEST_ON
				o.texcoord = v.texcoord;
			#endif
				return o;
			}

			float4 EncodeFloatRGBA(float v)
			{
				float4 kEncodeMul = float4(1.0, 255.0, 65025.0, 160581375.0);
				float kEncodeBit = 1.0 / 255.0;
				float4 enc = kEncodeMul * v;
				enc = frac(enc);
				enc -= enc.yzww * kEncodeBit;
				return enc;
			}


			float4 DepthOnlyFragmentSelf(VaryingsLeanSelf IN) : SV_TARGET

			{
			#ifdef _ALPHATEST_ON
				ClipHoles(IN.texcoord);
			#endif

				float3 ndcPos = IN.scrPos.xyz / IN.scrPos.w;//[0-1] D3D
				float2 screenUV = ndcPos.xy;
				float zdepth = ndcPos.z;

				zdepth = Linear01Depth(zdepth, _ZBufferParams);
				return EncodeFloatRGBA(zdepth);

			}

            ENDHLSL
        }
        

  
    }
}
