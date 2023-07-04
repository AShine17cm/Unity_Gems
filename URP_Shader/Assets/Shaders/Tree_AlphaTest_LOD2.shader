Shader "SC/Tree_LOD2"
{
     Properties
    {
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.362
        _AmbientBrightness  ("AmbientBrightness", Range (0, 3)) = 0.3
        _Contrast ("Contrast", Range (0, 2)) = 0.5
        _BaseBrightness ("BaseBrightness", Range (0, 2)) = 1
    }
		 CGINCLUDE
#pragma skip_variants LIGHTMAP_ON
			ENDCG
	SubShader
    {
        Tags {"Queue"="AlphaTest+39" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "LightMode" = "ForwardBase"}
		LOD 200
        Pass
        {
			Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
			#pragma multi_compile _ LOD_FADE_CROSSFADE

            sampler2D _MainTex;
            fixed _Cutoff;
            half _BaseBrightness;
            fixed _AmbientBrightness;
            half _Contrast;
            fixed _Color;

            struct v2f
            {
				float2 uv : TEXCOORD0;
				half3 diff : COLOR0;
				float4 pos : SV_POSITION;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_OUTPUT_STEREO
            };

			void billboard(inout appdata_base v)
			{
				const float3 local = float3(v.vertex.x, v.vertex.y, 0);
				const float3 offset = v.vertex.xyz - local;
				const fixed3 upVector = half3(0, 1, 0);
				const fixed3 forwardVector = UNITY_MATRIX_IT_MV[2].xyz;
				const fixed3 rightVector = normalize(cross(forwardVector, upVector));
				float3 position = 0;
				position += local.x * rightVector;
				position += local.y * upVector;
				position += local.z * forwardVector;
				v.vertex = float4(offset + position, 1);
				v.normal = forwardVector;
			}

			v2f vert (appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
					billboard(v);
				#endif
			
				o.uv = v.texcoord;
				o.pos = UnityObjectToClipPos(v.vertex);
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz)) + _BaseBrightness;
				o.diff = nl * _LightColor0.rgb * _Contrast;
				UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               fixed4 col = tex2D(_MainTex, i.uv);
				#ifdef LOD_FADE_CROSSFADE
					 clip(col.a * unity_LODFade.x - _Cutoff);
				#else
					clip(col.a - _Cutoff);
				#endif
               
				half3 lighting = i.diff + _AmbientBrightness * UNITY_LIGHTMODEL_AMBIENT.rgb;
				col.rgb *= lighting;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
            }
            ENDCG
        }
    }

    Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}