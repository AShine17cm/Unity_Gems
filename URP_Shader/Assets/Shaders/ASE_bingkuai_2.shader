Shader "ASE/bingkuai_2"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white" {}
		_Shininess("Shininess", Range( 0.01 , 128)) = 1
		_specular("specular",Range(0,10)) = 1
		_bingfaxian_01("bingfaxian_01", 2D) = "bump" {}
		_Normalpower("Normal power", Range( 0 , 5)) = 0
		_Color("Color", Color) = (0,0,0,0)
		_Colorpower("colorPower",Range(0,10)) = 1
		_Ooacity("Ooacity", Range( 0 , 1)) = 0.6
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}
	
	SubShader
	{
				
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One One , One One
		Cull Back
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		Offset 0 , 0
				
		Pass
		{
			Name "Unlitlight"
			Tags { "RenderPipeline" = "UniversalPipeline" }
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
			#include "Lighting.cginc"
			#include "AutoLight.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 ase_texcoord : TEXCOORD0;
				half4 ase_tangent : TANGENT;
				half3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				//float4 ase_lmap : TEXCOORD6;
				float4 ase_sh : TEXCOORD7;
			};

			//This is a late directive			
			uniform half _Normalpower;
			uniform sampler2D _bingfaxian_01;
			uniform half4 _bingfaxian_01_ST;
			uniform float _Shininess;
			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			uniform half _Ooacity;
			uniform half _specular;
			uniform half _Colorpower;
			
			v2f vert ( appdata v )
			{
			
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 ase_worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				half3 ase_worldTangent = UnityObjectToWorldDir(v.ase_tangent);
				o.ase_texcoord2.xyz = ase_worldTangent;
				half3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				half ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord4.xyz = ase_worldBitangent;				
				o.ase_color = v.color;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
								
				o.ase_sh.w = 0;
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
				float3 ase_worldPos = i.ase_texcoord.xyz;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(ase_worldPos);
				ase_worldViewDir = normalize(ase_worldViewDir);
				half3 worldSpaceLightDir = UnityWorldSpaceLightDir(ase_worldPos);
				half3 normalizeResult4_g6 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float2 uv_bingfaxian_01 = i.ase_texcoord1.xy * _bingfaxian_01_ST.xy + _bingfaxian_01_ST.zw;
				half3 _worldTangent = i.ase_texcoord2.xyz;
				half3 _worldNormal = i.ase_texcoord3.xyz;
				float3 _worldBitangent = i.ase_texcoord4.xyz;
				half3 tanToWorld0 = float3( _worldTangent.x, _worldBitangent.x, _worldNormal.x );
				half3 tanToWorld1 = float3( _worldTangent.y, _worldBitangent.y, _worldNormal.y );
				half3 tanToWorld2 = float3( _worldTangent.z, _worldBitangent.z, _worldNormal.z );
				float3 tanNormal12_g5 = UnpackScaleNormal( tex2D( _bingfaxian_01, uv_bingfaxian_01 ), _Normalpower );
				half3 worldNormal12_g5 = float3(dot(tanToWorld0,tanNormal12_g5), dot(tanToWorld1,tanNormal12_g5), dot(tanToWorld2,tanNormal12_g5));
				half3 normalizeResult64_g5 = normalize( worldNormal12_g5 );
				half dotResult19_g5 = dot( normalizeResult4_g6 , normalizeResult64_g5 );				
				UNITY_LIGHT_ATTENUATION(ase_atten, i, ase_worldPos)
				half4 temp_output_40_0_g5 = ( _LightColor0 * ase_atten );
				half dotResult14_g5 = dot( normalizeResult64_g5 , worldSpaceLightDir );
				UnityGIInput data34_g5;
				UNITY_INITIALIZE_OUTPUT( UnityGIInput, data34_g5 )								
				UnityGI gi34_g5 = UnityGI_Base(data34_g5, 1, normalizeResult64_g5);
				float2 uv_MainTex = i.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half4 tex2DNode1 = tex2D( _MainTex, uv_MainTex );
				half4 temp_output_42_0_g5 = ( _Color * tex2DNode1 );
				half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Color.rgb;
				half3 diffuse = max( dotResult14_g5 , 0.0 ) * tex2DNode1.rgb * _LightColor0.rgb * _Colorpower;
				half4 appendResult67 = (half4(_specular *( i.ase_color *  pow( max( dotResult19_g5 , 0.0 ) ,  _Shininess) ) + half4 (diffuse,1.0) + half4( ambient,1.0)));
				

				return fixed4 (appendResult67 * _Ooacity * i.ase_color.a);
			}
			ENDCG
		}
	}
	
	
	
}
