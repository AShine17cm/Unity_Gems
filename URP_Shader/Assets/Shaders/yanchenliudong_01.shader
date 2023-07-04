// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASE/yanchenliudong_01"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (0.9716981,0.9716981,0.9716981,0)
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_Colorpower("Colorpower", Float) = 1
		_U_speed("U_speed", Float) = 0
		_V_speed("V_speed", Float) = 0
		_TextureSample1("Texture Sample 1", 2D) = "white" {}
		_TextureSample2("Texture Sample 2", 2D) = "white" {}
		_texraodongUV("tex & raodong UV", Vector) = (0,0,0,0)
		_raodongpower("raodongpower", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

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
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags {  }
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
				float4 ase_texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
			};

			uniform float4 _Color;
			uniform sampler2D _TextureSample0;
			uniform sampler2D _TextureSample1;
			uniform float4 _texraodongUV;
			uniform float _raodongpower;
			uniform float _U_speed;
			uniform float _V_speed;
			uniform float _Colorpower;
			uniform sampler2D _TextureSample2;
			uniform float4 _TextureSample2_ST;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				float2 appendResult49 = (float2(_texraodongUV.z , _texraodongUV.w));
				float2 panner26 = ( 1.0 * _Time.y * float2( 0.2,-0.1 ) + float2( 0,0 ));
				float2 uv027 = i.ase_texcoord.xy * appendResult49 + panner26;
				float2 appendResult48 = (float2(_texraodongUV.xy));
				float2 appendResult22 = (float2(_U_speed , _V_speed));
				float2 panner8 = ( 1.0 * _Time.y * appendResult22 + float2( 0,0 ));
				float2 uv07 = i.ase_texcoord.xy * appendResult48 + panner8;
				float4 tex2DNode2 = tex2D( _TextureSample0, ( ( tex2D( _TextureSample1, uv027 ).r * _raodongpower ) + uv07 ) );
				float2 uv_TextureSample2 = i.ase_texcoord.xy * _TextureSample2_ST.xy + _TextureSample2_ST.zw;
				float4 appendResult4 = (float4(( _Color * tex2DNode2 * _Colorpower ).rgb , ( tex2DNode2.a * tex2D( _TextureSample2, uv_TextureSample2 ).r )));
				
				
				finalColor = ( appendResult4 * i.ase_color * i.ase_color.a * _Color.a );
				return finalColor;
			}
			ENDCG
		}
	}
	
	
	
}
