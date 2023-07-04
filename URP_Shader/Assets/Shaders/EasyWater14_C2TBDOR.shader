Shader "EWater/Reflective/EasyWater14_C2TBDOR"
{
	Properties 
	{
_Color("_Color", Color) = (1,1,1,1)
_Texture1("_Texture1", 2D) = "black" {}
_BumpMap1("_BumpMap1", 2D) = "black" {}
_Texture2("_Texture2", 2D) = "black" {}
_BumpMap2("_BumpMap2", 2D) = "black" {}
_MainTexSpeed("_MainTexSpeed", Float) = 0
_Bump1Speed("_Bump1Speed", Float) = 0
_Texture2Speed("_Texture2Speed", Float) = 0
_Bump2Speed("_Bump2Speed", Float) = 0
_DistortionMap("_DistortionMap", 2D) = "black" {}
_DistortionSpeed("_DistortionSpeed", Float) = 0
_DistortionPower("_DistortionPower", Range(0,0.02) ) = 0
_Specular("_Specular", Range(0,7) ) = 1
_Gloss("_Gloss", Range(0.3,2) ) = 0.3
_Opacity("_Opacity", Range(-0.2,1) ) = 0

	}
		CGINCLUDE
#pragma skip_variants LIGHTMAP_ON
	ENDCG
	SubShader 
	{
		Tags
		{
		"Queue"="Transparent"
		"IgnoreProjector"="True"
		"RenderType"="Transparent"
		}

		
		Cull off
		ZWrite On
		ZTest LEqual
		ColorMask RGBA
		Blend SrcAlpha OneMinusSrcAlpha
		
		
		CGPROGRAM
		#pragma surface surf BlinnPhongEditor  alpha
		#pragma target 3.0
		#pragma multi_compile_fog
		
		
		fixed4 _Color;
		uniform sampler2D _Texture1;
		uniform sampler2D _BumpMap1;
		uniform sampler2D _Texture2;
		uniform sampler2D _BumpMap2;
		half _MainTexSpeed;
		half _Bump1Speed;
		half _Texture2Speed;
		half _Bump2Speed;
		uniform sampler2D _DistortionMap;
		half _DistortionSpeed;
		half _DistortionPower;
		fixed _Specular;
		fixed _Gloss;
		float _Opacity;
		float _ReflectPower;

		
			
		inline fixed4 LightingBlinnPhongEditor_PrePass (SurfaceOutput s, fixed4 light)
		{
			fixed3 spec = light.a * s.Gloss;
			fixed4 c;
			c.rgb = (s.Albedo * light.rgb + light.rgb * spec);
			c.a = s.Alpha;
			return c;
		}

		inline fixed4 LightingBlinnPhongEditor (SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			fixed3 h = normalize (lightDir + viewDir);
			
			fixed diff = max (0, dot ( lightDir, s.Normal ));
			
			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, s.Specular*128.0);
			
			fixed4 res;
			res.rgb = _LightColor0.rgb * diff;
			res.w = spec * Luminance (_LightColor0.rgb);
			res *= atten * 2.0;

			return LightingBlinnPhongEditor_PrePass( s, res );
		}
		
		struct Input {
			float3 viewDir;
			float2 uv_DistortionMap;
			float2 uv_Texture1;
			float2 uv_Texture2;
			float2 uv_BumpMap1;
			float2 uv_BumpMap2;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			o.Normal = float3(0.0,0.0,1.0);
			o.Alpha = 1.0;
			o.Albedo = 0.0;
			o.Emission = 0.0;
			o.Gloss = 0.0;
			o.Specular = 0.0;
			
			float4 ViewDirection=float4( IN.viewDir.x, IN.viewDir.y,IN.viewDir.z *10,0 );
			float4 Normalize0=normalize(ViewDirection);			
			
			
			
			
			// Animate distortionMap 
			float DistortSpeed=_DistortionSpeed * _Time;
			float2 DistortUV=(IN.uv_DistortionMap.xy) + DistortSpeed;
			// Create Normal for DistorionMap
			float4 DistortNormal = tex2D(_DistortionMap,DistortUV);
			// Multiply Tex2DNormal effect by DistortionPower
			float FinalDistortion = ( DistortNormal.r -0.5) * _DistortionPower;
			
			// Apply DistorionMap in Reflection's UV
			//float2 ReflexUV= float2((Normalize0.x + 1) * 0.5, (Normalize0.y + 1) * 0.5)  + FinalDistortion *5;
			//float4 Tex2D2=tex2D(_Reflection,ReflexUV);
			
			// Get Fresnel from viewDirection angle
			//float3 Fresnel0_1_NoInput = float3(0,0,1);
			//float Fresnel0=(1.0 - dot( normalize( float3( IN.viewDir.x, IN.viewDir.y,IN.viewDir.z ).xyz), normalize( Fresnel0_1_NoInput.xyz ) ));
			
			// Multiply reflection by fresnel so it's stronger when it's far
			//float Multiply12 =_ReflectPower * Fresnel0;
			//float4 FinalReflex = Tex2D2 * Multiply12;
			
			// Animate MainTex
			float Multiply2=_Time * _MainTexSpeed;
			float2 MainTexUV=(IN.uv_Texture1.xy  + FinalDistortion) + Multiply2; 
			
			// Apply Distorion in MainTex
			float4 Tex2D0=tex2D(_Texture1,MainTexUV);
			
			// Animate Texture2
			float Multiply3=_Time * _Texture2Speed;
			float2 Tex2UV=(IN.uv_Texture2.xy  - FinalDistortion) + Multiply3;
			
			// Apply Distorion in Texture2
			float4 Tex2D1=tex2D(_Texture2,Tex2UV); 
			
			// Merge MainTex and Texture2
			float4 TextureMix=Tex2D0 * Tex2D1;
			
			// Add TextureMix with Reflection
			// float4 TexNReflex = lerp(TextureMix, FinalReflex, _ReflectPower);
			
			
			// Merge Textures, Reflection and Color
			float4 FinalDiffuse=_Color * TextureMix; 			
			
			
			// Animate BumpMap1
			float Multiply8=_Time * _Bump1Speed;
			float2 Bump1UV=(IN.uv_BumpMap1.xy + FinalDistortion) + Multiply8;
			
			// Apply Distortion to BumpMap			
			half4 Tex2D3=tex2D(_BumpMap1,Bump1UV );
			
			// Animate BumpMap2
			half Multiply9=_Time * _Bump2Speed;
			half2 Bump2UV=(IN.uv_BumpMap2.xy  - FinalDistortion) + Multiply9;
			
			// Apply Distortion to BumpMap2						
			fixed4 Tex2D4=tex2D(_BumpMap2,Bump2UV) ;
			
			// Get Average from BumpMap1 and BumpMap2
			fixed4 AvgBump= (Tex2D3 + Tex2D4) / 2;
			
			// Unpack Normals
			fixed4 UnpackNormal1=float4(UnpackNormal(AvgBump).xyz, 1.0);
			
			
			float3 alphaByView =  abs(dot(normalize(IN.viewDir),o.Normal)) ;
			
			
			//o.Emission = FinalReflex;			
			o.Albedo = FinalDiffuse;
			o.Normal = UnpackNormal1;
			o.Specular = _Gloss;
			o.Gloss = _Specular;
			o.Alpha = (2 * _Opacity) - alphaByView;
			o.Normal = normalize(o.Normal);
		}
	ENDCG
	}
	Fallback "Diffuse"
}