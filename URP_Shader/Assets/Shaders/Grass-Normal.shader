Shader "Custom/Grass-Normal"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
		_Brightness("Brightness", Float) = 1
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.05
		_Range("Range",Float) = 0.1
		_Speed("Speed",Float) = 3
		_CameraDistance("Camera Distance",Float) = 100
    }
		CGINCLUDE
#pragma skip_variants LIGHTMAP_ON
			ENDCG
	SubShader
    {
        Tags{ "Queue" = "AlphaTest+40" "IgnoreProjector" = "True"  "RenderType"="TransparentCutout" }
		LOD 300

        Pass
        {
			Cull Off

			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_fog
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			fixed4 _Color;
			half _Range;
			fixed _Cutoff;
			half _Speed;
			half _Brightness;
			half _CameraDistance;

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                half2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
				float4 worldNormal : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				SHADOW_COORDS(3)
				UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
			#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
				half offset = sin((_Time.y + v.vertex.x + v.vertex.z) * _Speed) * max(0, v.vertex.y - 0.2) * _Range;
				v.vertex += half4(offset, 0, offset, 0);
			#endif


                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.worldNormal.xyz = UnityObjectToWorldNormal(v.normal);
				o.worldNormal.w = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);
                UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff - step(_CameraDistance, i.worldNormal.w));
				fixed3 worldNormal = normalize(i.worldNormal.xyz);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
			 	fixed3 diffuse = _LightColor0.rgb * abs(dot(worldNormal, worldLightDir)) * _Brightness;
				fixed3 lighting = diffuse * SHADOW_ATTENUATION(i) + UNITY_LIGHTMODEL_AMBIENT.rgb;
				col.rgb *= lighting;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags{ "Queue" = "AlphaTest+40" "IgnoreProjector" = "True"  "RenderType"="TransparentCutout" }
		LOD 250

        Pass
        {
			Cull Off

			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_fog
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			fixed4 _Color;
			fixed _Cutoff;
			half _Brightness;

            struct appdata
            {
                float4 vertex : POSITION;
				fixed3 normal : NORMAL;
                half2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				UNITY_FOG_COORDS(2)
				SHADOW_COORDS(3)
				UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff);
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
			 	fixed3 diffuse = _LightColor0.rgb * abs(dot(worldNormal, worldLightDir)) * _Brightness;
				fixed3 lighting = diffuse * SHADOW_ATTENUATION(i) + UNITY_LIGHTMODEL_AMBIENT.rgb;
				col.rgb *= lighting;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }

	Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
