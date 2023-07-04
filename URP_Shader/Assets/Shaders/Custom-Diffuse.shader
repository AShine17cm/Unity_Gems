// Simplified Diffuse shader. Differences from regular Diffuse one:
// - no Main Color
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "Custom/Diffuse" {
Properties {
	_MainTex ("Base (RGB) Specular (A)", 2D) = "white" {}
	_Brightness ("Brightness", Range (0, 2)) = 1
	_AmbientBrightness  ("AmbientBrightness", Range (0, 3)) = 0
}
CGINCLUDE
#pragma skip_variants LIGHTMAP_ON
ENDCG
SubShader { 
	Tags { "RenderType"="Opaque" }
	LOD 250
	
CGPROGRAM
#pragma surface surf MobileBlinnPhong exclude_path:prepass  noforwardadd halfasview interpolateview
#pragma multi_compile_instancing

sampler2D _MainTex;
half _Brightness;
half _AmbientBrightness;

inline fixed4 LightingMobileBlinnPhong (SurfaceOutput s, half3 lightDir, half3 halfDir, half atten)
{
 	half3 attenColor = _LightColor0.rgb * _Brightness * atten;
	half NdotL = dot(s.Normal, lightDir);
    half3 diff = max(0, NdotL ) * attenColor + _AmbientBrightness * UNITY_LIGHTMODEL_AMBIENT.rgb;
	float4 c;
	c.rgb = (s.Albedo * diff);
	UNITY_OPAQUE_ALPHA(c.a);
	return c;
}

struct Input {
	float2 uv_MainTex;
};

void surf (Input IN, inout SurfaceOutput o) {
	float4 tex = tex2D(_MainTex, IN.uv_MainTex);
	o.Albedo = tex.rgb;
}
ENDCG
}

FallBack "Custom/VertexLit"
}
