Shader "Mg/Plant/Fruit"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		tintA("Green",Color) = (0,1,0,1)
		//tintB("Yellow",Color)=(1,1,0,1)
		amt("Amount of curve",range(0,1))=0
		wrap("wrap of light",float)=1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "UniversalForward" }
			//Cull Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			//#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			//#include "UnityCG.cginc"
			//#include "AutoLight.cginc"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitForwardPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;//必须 pos,阴影相关
				float2 uv : TEXCOORD0;
				float3 normal:TEXCOORD1;
				float amt : TEXCOORD2;
				float spec:TEXCOORD3;
				float3 coord:TEXCOORD4;
				//SHADOW_COORDS(4) // put shadows data into TEXCOORD 3
			};
			UNITY_INSTANCING_BUFFER_START(Props)
				UNITY_DEFINE_INSTANCED_PROP(float, amt)
			UNITY_INSTANCING_BUFFER_END(Props)
			//float amt;
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				float3 posWS = TransformObjectToWorld(v.vertex);
				o.pos = TransformWorldToHClip(posWS);
				o.uv = v.uv;
				o.normal = v.normal;// 
				o.amt = UNITY_ACCESS_INSTANCED_PROP(Props, amt);
				float3 wldN = TransformObjectToWorldNormal(v.normal);
				float3 viewDir = normalize(_WorldSpaceCameraPos - posWS);
				float3 hvec =normalize( viewDir+float3(0,1,0));// normalize(viewDir + _WorldSpaceLightPos0.xyz);
				float spec = max(0, dot(hvec, wldN));

				o.spec =pow(spec,4);
				o.coord= TransformWorldToShadowCoord(posWS);
				return o;
			}
			sampler2D _MainTex;
			float4 tintA;
			float wrap;
			fixed4 frag(v2f i) : SV_Target
			{
				float3 wldN = UnityObjectToWorldNormal(i.normal);
				float diff = dot(wldN, _WorldSpaceLightPos0.xyz);
				
				//spec = (spec + wrap) / (1 + wrap);
				//spec = spec * spec;

				diff = abs(diff);
				diff = (diff + wrap) / (1 + wrap);
				//diff = diff * diff;

				fixed4 col = tex2D(_MainTex, i.uv);
				col = lerp(tintA, col, i.amt);
				//Shadow
				float shadow = SHADOW_ATTENUATION(i);
				col = col * (diff * shadow+i.spec);

				return col;
			}
			ENDHLSL
		}
		UsePass "Mg/MgComm/XSOLIDSHADOW"
	}
}
