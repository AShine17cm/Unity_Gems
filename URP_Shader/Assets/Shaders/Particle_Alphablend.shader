// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "SC/Particles/fx_AlphaBlend" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_Brightness("Brightness", Range(0,100)) = 1.0
	_Saturation("Saturation", Range(0,1)) = 1.0
	_Contrast("Contrast", Range(0,1)) = 1.0
	_ContrastColor ("Contrast Color", Color) = (0.5,0.5,0.5,1)
	_AlphaPower("Alpha power", Range(0, 100)) = 1.0
	_MainTex ("Particle Texture", 2D) = "white" {}
	_AlphaTex ("Alpha Texture", 2D) = "white" {}
	_SpeedX("UV speed X", Range(-3, 3)) = 0
	_SpeedY("UV speed Y", Range(-3, 3)) = 0
	_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	//AlphaTest Greater .01
	ColorMask RGBA
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	
	// ---- Fragment program cards
	SubShader {
		Pass {
		
			CGPROGRAM
						#pragma prefer_hlslcc gles
#pragma exclude_renderers d3d11_9x
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_particles
            #pragma multi_compile_instancing
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			float4 _TintColor;
			half _Brightness;
			half _Saturation;
			half _Contrast;
			float4 _ContrastColor;
			half _AlphaPower;
			half _SpeedX;
			half _SpeedY;
			
			struct appdata_t {
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 texcoordA : TEXCOORD1;
			};

			struct v2f {
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
				#ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD1;
				#endif
			};
			
			float4 _MainTex_ST;
			float4 _AlphaTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				#ifdef SOFTPARTICLES_ON
				o.projPos = ComputeScreenPos (o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
				o.color = v.color;
				o.texcoord.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.texcoord.zw = TRANSFORM_TEX(v.texcoordA,_AlphaTex) + frac(float2(_SpeedX*_Time.y, _SpeedY*_Time.y));
				return o;
			}

			sampler2D _CameraDepthTexture;
			float _InvFade;
			
			half4 frag (v2f i) : COLOR
			{
				#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r);
				float partZ = i.projPos.z;
				float fade = saturate (_InvFade * (sceneZ-partZ));
				i.color.a *= fade;
				#endif
				
				half4 texColor = tex2D(_MainTex, i.texcoord.xy);
				texColor.rgb = texColor.rgb * _Brightness;
				
				fixed luminance = 0.2125 * texColor.r + 0.7154 * texColor.g + 0.0721 * texColor.b;
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				texColor.rgb = lerp(luminanceColor, texColor.rgb, _Saturation);
				
				texColor.rgb = lerp(_ContrastColor.rgb, texColor.rgb, _Contrast);
				
				half4 c = 1.0f * _TintColor * i.color * texColor;
				
				half4 alphaColor = tex2D(_AlphaTex, i.texcoord.zw);
				half alphaA = (0.299*alphaColor.r+0.587*alphaColor.r+0.114*alphaColor.r)*_AlphaPower;
				c.a = c.a * alphaA;
				return c;
			}
			ENDCG 
		}
	} 	
	
	// ---- Dual texture cards
	SubShader {
		Pass {
			SetTexture [_MainTex] {
				constantColor [_TintColor]
				combine constant * primary
			}
			SetTexture [_MainTex] {
				combine texture * previous DOUBLE
			}
		}
	}
	
	// ---- Single texture cards (does not do color tint)
	SubShader {
		Pass {
			SetTexture [_MainTex] {
				combine texture * primary
			}
		}
	}
}
}
