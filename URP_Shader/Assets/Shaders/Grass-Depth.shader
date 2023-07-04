Shader "Custom/Grass-Depth"
{
    Properties
    {
        _Color("Main Color", Color) = (1,1,1,1)
		[NoScaleOffset] _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.05
		_Range("Range",Float) = 0.1
		_Speed("Speed",Float) = 3
		_CameraDistance("Camera Distance",Float) = 100
    }

    SubShader
    {
        Tags{ "Queue" = "AlphaTest+20" "IgnoreProjector" = "True" "RenderType"="TransparentCutout" }
		LOD 300
		ColorMask 0
		Cull Off
		ZTest LEqual
		ZWrite On

        Pass
        {
			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _Color;
			half _Range;
			fixed _Cutoff;
			half _Speed;
			half _CameraDistance;

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
				float cameraDistance : TEXCOORD1;
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
				o.cameraDistance = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff - step(_CameraDistance, i.cameraDistance));
				return col;
            }
            ENDCG
        }
    }

	SubShader
    {
        Tags{ "Queue" = "AlphaTest+20" "IgnoreProjector" = "True" "RenderType"="TransparentCutout" }
		LOD 250
		ColorMask 0
		Cull Off
		ZTest LEqual
		ZWrite On

        Pass
        {
			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _Color;
			fixed _Cutoff;
			half _CameraDistance;

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
				float cameraDistance : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.cameraDistance = distance(mul(unity_ObjectToWorld, v.vertex), _WorldSpaceCameraPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
				clip(col.a - _Cutoff - step(_CameraDistance, i.cameraDistance));
                return col;
            }
            ENDCG
        }
    }

	Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
