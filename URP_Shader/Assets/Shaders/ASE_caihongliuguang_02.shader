
Shader "ASE/caihongliuguang_01"
{
	Properties
	{
		_Texture0("Texture 0", 2D) = "white" {}
		[HDR]_Color("Color", Color) = (1,1,1,1)
		_Speed("Speed", Vector) = (0,0,0,0)
	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha , SrcAlpha OneMinusSrcAlpha
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
		//only defining to not throw compilation error over Unity 5.5
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
				float4 _texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 _texcoord : TEXCOORD0;
			};

			uniform float4 _Color;
			uniform sampler2D _Texture0;
			uniform float4 _Texture0_ST;
			uniform float4 _Speed;
			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o._texcoord.xy = v._texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o._texcoord.zw = 0;
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
				float2 uv_Texture0 =i._texcoord.xy * i._texcoord.xy + _Texture0_ST.zw;
				
				float2 appendResult13 = (float2(_Speed.x , _Speed.y));
				//float2 uv015 = i._texcoord.xy * appendResult13 + float2( 0,0 );
				float2 appendResult14 = (float2(_Speed.z , _Speed.w));
				float2 panner4 = ( 1.0 * _Time.y * appendResult14 + float2( 0,0 ));
				float2 uv08 = i._texcoord.xy *appendResult13 + panner4;
				float4 appendResult7 = (float4(( _Color * tex2D( _Texture0, uv_Texture0 ) ).rgb , ( _Color.a * tex2D( _Texture0, uv08 ).a )));
				
				
				finalColor = appendResult7;
				return finalColor;
			}
			ENDCG
		}
	}
	
	
	
}
