#ifndef MG_UNITY_INPUT_INCLUDED
#define MG_UNITY_INPUT_INCLUDED

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
float4x4 unity_WorldToObject;
float4 unity_LODFade;
real4 unity_WorldTransformParams;		//real 依赖于硬件平台
CBUFFER_END

float4x4 unity_MatrixVP;
float4x4 unity_MatrixV;
float4x4 glstate_matrix_projection;

float3 _WorldSpaceCameraPos;
float4 _ProjectionParams;			//UV 的 V 上下翻转，和图形API有关
#endif