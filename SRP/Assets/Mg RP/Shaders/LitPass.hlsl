#ifndef MG_LIT_PASS_INCLUDED
#define MG_LIT_PASS_INCLUDED

#include "../ShaderLibrary/Common.hlsl"
#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/Shadows.hlsl"
#include "../ShaderLibrary/Light.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);


UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
	UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
	UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
	//BRDF
	UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
	UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

//顶点输入
struct Attributes 
{
	float3 posOS:POSITION;
	float3 normalOS:NORMAL;
	float2 baseUV : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
//顶点函数 输出
struct Varyings {
	float4 posCS : SV_POSITION;
	float3 posWS:VAR_POSITON;
	float3 normalWS:VAR_NORMAL;
	float2 baseUV:VAR_BASE_UV;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


Varyings LitPassVertex(Attributes input)
{
	Varyings output;

	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);

	float3 posWS = TransformObjectToWorld(input.posOS);
	output.posWS = posWS;
	output.posCS = TransformWorldToHClip(posWS);
	output.normalWS = TransformObjectToWorldNormal(input.normalOS);

	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	output.baseUV = input.baseUV * baseST.xy + baseST.zw;
	return output;
}

float4 LitPassFragment(Varyings input) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(input);
	float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV);
	float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

	float4 base = baseMap * baseColor;
#if defined(_CLIPPING)
	clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
#endif
	

	Surface surface;
	surface.position = input.posWS;
	surface.normal = normalize(input.normalWS);
	surface.viewDir = normalize(_WorldSpaceCameraPos - input.posWS);
	surface.color = base.rgb;
	surface.alpha = base.a;
	//BRDF
	surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	surface.smoothness =UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
	BRDF brdf = GetBRDF(surface);
	float3 color = GetLighting(surface,brdf);

	//float shadow = GetDirectionalShadowAttenuation(surface);
	//color *= shadow;
	return float4(color,surface.alpha);

}

#endif