#ifndef VFX_INPUT_INCLUDED
#define VFX_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _MaskMap_ST;
float4 _PannerTex_ST;
float4 _DissloveTex_ST;
float4 _Offset_ST;
float4 _MainUVSpeedAndRota,_MaskUVSpeedAndRota,_PannerUVSpeedAndRota,_DissloveUVSpeedAndRota,_OffsetUVSpeedAndRota;
//half _MainRota, _MaskRota,_PannerRota,_DissRota,_OffsetRota;
////half _MainPolar,_MaskPolar,_PannerPolar,_DissPolar,_OffsetPolar;
//half _Main_U_Speed,_Main_V_Speed,_Mask_U_Speed,_Mask_V_Speed,_Panner_U_Speed,
//    _Panner_V_Speed,_Diss_U_Speed,_Diss_V_Speed,_Offset_U_Speed,_Offset_V_Speed;
//half _MaskIntensity,_PannerIntensity,_OffsetIntensity,_DissloveIntensity;
half _Hardness,_Extrusion;
half _Main_U_Offset,_Main_V_Offset;
half _Edgewidth;
half _FresnelWidth,_FresnelIntensity,_Fresnel;
half4 _FresnelColor,_EdgeColor,_BaseColor;
float _Mode;
CBUFFER_END

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap);            SAMPLER(sampler_MaskMap);
TEXTURE2D(_PannerTex);          SAMPLER(sampler_PannerTex);
TEXTURE2D(_DissloveTex);        SAMPLER(sampler_DissloveTex);
TEXTURE2D(_Offset);			    SAMPLER(sampler_Offset);

	struct VertexInput{

	float4 positionOS	: POSITION;
	float3 normalOS		: NORMAL;
	half4 color         : COLOR;
	float4 texcoord1	: TEXCOORD0;
	float4 texcoord2	: TEXCOORD1;

	UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct VertexOutput{

	float4 positionCS    : SV_POSITION;
	float3 positionWS    : TEXCOORD0;
			
	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	float4 ShadowCoord   : TEXCOORD1;
	#endif

			
	half4 color         : COLOR;
			
	half4 fogFactor		: TEXCOORD2;

	float4 texcoord3	: TEXCOORD3;
	float4 texcoord4	: TEXCOORD4;

	float4 texcoord5	: TEXCOORD5;
	UNITY_VERTEX_INPUT_INSTANCE_ID
			
	};

#endif //URP_INPUT_INCLUDED