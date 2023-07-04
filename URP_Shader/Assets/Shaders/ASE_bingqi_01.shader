
Shader "ASE/bingqi_01"
{
	Properties
	{
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		[HDR]_Color("Color", Color) = (1,1,1,0)
		_TextureSample1("Texture Sample 1", 2D) = "white" {}
	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One , One One
		Cull Off
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		
		
		
		Pass
		{
			Name "Unlit"
			
			CGPROGRAM
		 #pragma prefer_hlslcc gles
#pragma exclude_renderers d3d11_9x

#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX

		#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 ase_texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
			};

			uniform float4 _Color;
			uniform sampler2D _TextureSample0;
			uniform sampler2D _TextureSample1;
			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_color = v.color;
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				
				o.ase_texcoord.zw = 0;
				float3 vertexValue =  float3(0,0,0) ;
				
				v.vertex.xyz += vertexValue;

				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				float2 uv09 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv012 = i.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 panner11 = ( 1.0 * _Time.y * float2( 0.1,0.15 ) + uv012);
				float4 tex2DNode1 = tex2D( _TextureSample0, ( uv09 + ( tex2D( _TextureSample1, panner11 ).r * 0.15 ) ) );
				
				
				finalColor = ( i.ase_color * _Color * tex2DNode1 * i.ase_color.a * _Color.a * tex2DNode1.a );
				return finalColor;
			}
			ENDCG
		}
	}
	
	
	
}
