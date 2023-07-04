Shader "Shader Forge/liuguang_03" {
	Properties{
		_yanse_01("yanse_01", Color) = (0.5,0.5,0.5,1)
		_raodongwenli("raodongwenli", 2D) = "white" {}
		_speed("speed", Range(-1, 5)) = 0
		_yanseqingdu("yanseqingdu", Range(0, 5)) = 0
		[HideInInspector]_Cutoff("Alpha cutoff", Range(0,1)) = 0.5
	}
		CGINCLUDE
		#pragma skip_variants LIGHTMAP_ON
		ENDCG
		SubShader{
			Tags {
				"IgnoreProjector" = "True"
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
			    
			}
			Pass {
				Name "FORWARD"
				Tags {
					

				}

			    cull off
				Blend One One
				ZWrite Off

				CGPROGRAM
			 #pragma prefer_hlslcc gles
#pragma exclude_renderers d3d11_9x
				#pragma vertex vert
				#pragma fragment frag
				#define UNITY_PASS_FORWARDBASE
				#include "UnityCG.cginc"
				#pragma multi_compile_fwdbase
				#pragma multi_compile_fog
				#pragma multi_compile_instancing
				#pragma target 3.0
				uniform float4 _yanse_01;
				uniform sampler2D _raodongwenli; uniform float4 _raodongwenli_ST;
				uniform float _speed;
				uniform float _yanseqingdu;
				struct VertexInput {
					float4 vertex : POSITION;
					float2 texcoord0 : TEXCOORD0;
				};
				struct VertexOutput {
					float4 pos : SV_POSITION;
					float2 uv0 : TEXCOORD0;
					UNITY_FOG_COORDS(1)
				};
				VertexOutput vert(VertexInput v) {
					VertexOutput o = (VertexOutput)0;
					o.uv0 = v.texcoord0;
					o.pos = UnityObjectToClipPos(v.vertex);
					UNITY_TRANSFER_FOG(o,o.pos);
					return o;
				}
				float4 frag(VertexOutput i) : COLOR {
					////// Lighting:
					////// Emissive:
									float4 node_9606 = _Time;
									float2 node_6783 = (i.uv0 + ((i.uv0 + node_9606.g*float2(1,1))*_speed));
									float4 _raodongwenli_var = tex2Dlod(_raodongwenli,float4(TRANSFORM_TEX(node_6783, _raodongwenli),0.0,_speed));
									float3 emissive = (_raodongwenli_var.rgb*(_yanse_01.rgb*_yanseqingdu) * _yanse_01.a);
									float3 finalColor = emissive;
									fixed4 finalRGBA = fixed4(finalColor,_raodongwenli_var.a);
									UNITY_APPLY_FOG_COLOR(i.fogCoord, finalRGBA, fixed4(0,0,0,1));
									return finalRGBA;
								}
								ENDCG
							}
		}
			CustomEditor "ShaderForgeMaterialInspector"
}
