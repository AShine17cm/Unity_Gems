#ifndef URP_FRUIT_INCLUDED
#define URP_FRUIT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
	float4 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 texcoord : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float2 uv : TEXCOORD0;
	float4 positionCS : SV_POSITION;
	float3 normalWS : TEXCOORD1;

	float3 vertexLight:TEXCOORD2;
	half fogFactor : TEXCOORD3;
	float4 screenPos    : TEXCOORD4;
	float4 shadowCoord : TEXCOORD5;
	float amt : TEXCOORD6;
	//DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);//²ÎÊý 7 ÊÇ TEXCOORD_7
	//float3 positionWS:TEXCOORD2;
};
UNITY_INSTANCING_BUFFER_START(Props)
UNITY_DEFINE_INSTANCED_PROP(float, amt)
UNITY_INSTANCING_BUFFER_END(Props)


Varyings vert(Attributes input)
{
	Varyings output = (Varyings)0;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input,output);
	output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

	float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
	float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
	float4 positionCS = TransformWorldToHClip(positionWS);

	output.positionCS = positionCS;
	//output.positionWS = positionWS;
	output.normalWS = normalWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	output.shadowCoord = TransformWorldToShadowCoord(positionWS);
#else
	output.shadowCoord.xyz = positionWS;
#endif
	//OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
	//OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
	output.vertexLight = VertexLighting(positionWS, normalWS);
	output.fogFactor = ComputeFogFactor(positionCS.z);
	output.screenPos = ComputeScreenPos(output.positionCS);

	//float3 viewDir = normalize(_WorldSpaceCameraPos - positionWS);
	//ouput.amt = UNITY_ACCESS_INSTANCED_PROP(Props, amt);
	return output;
}
float4 tintA;
float wrap;
half4 frag(Varyings input) : SV_Target
{
	float4 base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
	half4 shadowCoord = TransformWorldToShadowCoord(input.shadowCoord.xyz);
	half3 bakedGI = 0;
	half3 emission = 0;
	base = lerp(tintA, base, input.amt);
	//base.rgb = Lambert(base.rgb, input.normalWS, shadowCoord, bakedGI, emission);
	Light mainLight = GetMainLight(shadowCoord);
	half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
	half3 diffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, input.normalWS);
	half3 finalColor = diffuseColor * base.rgb;

	return half4(finalColor,base.a);
}
#endif //URP_VERTEXLIT_PASS_INCLUDED
