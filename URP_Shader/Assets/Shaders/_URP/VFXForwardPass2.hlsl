// Most from universal@7.3.1 LitForwardPass.hlsl

#ifndef URP_VFX_PASS2_INCLUDED
#define URP_VFX_PASS2_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float2 PolarAndRotator(float2 uvTex,half Tha,float uSpeed,float vSpeed)
{   
	//中心锚点
	float2 piv=float2(0.5,0.5);
	//计算旋转矩阵
	float cosTha=cos(Tha);

	float sinTha=sin(Tha);

	float2x2 ratatorM=float2x2(cosTha,-sinTha,sinTha,cosTha);

	float2 uvNew=mul(uvTex-piv,ratatorM)+piv;

	//将uv的0点移到中心
	float2 uv=uvNew * 2.0 - 1.0;
	//计算各个象限到0点的距离
	float distance=length(uv);
	//处理从中心到边缘的挤压
	float powDis=pow(distance,_Extrusion);
	//4象限的弧度范围转到0~1
	float angle=atan2(uv.y,uv.x) / (2.0 * PI) + 0.5;
				
	//整合后的uv
	float2 appendUV=float2(powDis,angle);
	//缩放和偏移
	//float2 UV=appendUV * _Main_ScaleAndOffset.xy+_Main_ScaleAndOffset.zw;
	//uv动画偏移
	float2 uvAnim=float2(uSpeed,vSpeed) *_Time.y;
	//判断是否用极坐标还是直角坐标系
	//float2 panner=( 1.0 * uvAnim + (( Polar )?( appendUV ):( uvNew )));
	float2 panner=( 1.0 * uvAnim +  uvNew );//去掉极坐标
	return panner;
}
			
VertexOutput Vert(VertexInput input)
{
	VertexOutput output = (VertexOutput)0;
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
				
	float3 worldNormal=TransformObjectToWorldNormal(input.normalOS);
	output.texcoord5.xyz=worldNormal;
	output.texcoord5.w=0;
				
	output.texcoord3.xy=input.texcoord1.xy;
	output.texcoord4=input.texcoord2;
			
	output.color=input.color;
				
	output.texcoord3.zw=0;
			

	#ifdef ASE_ABSOLUTE_VERTEX_POS
		float3 defaultVertexValue = input.positionOS.xyz;
	#else
		float3 defaultVertexValue = float3(0, 0, 0);
	#endif
			 
	float3 vertexValue = defaultVertexValue;
				
				
	#ifdef ASE_ABSOLUTE_VERTEX_POS
		input.positionOS.xyz = vertexValue;
	#else
		input.positionOS.xyz += vertexValue;
	#endif
	input.normalOS=input.normalOS;

				
	output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
	output.positionCS = TransformWorldToHClip( output.positionWS  );
	#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR) 
	VertexPositionInputs vertexInput = (VertexPositionInputs)0;
	vertexInput.positionWS = output.positionWS;
	vertexInput.positionCS = output.positionCS;
	output.ShadowCoord = GetShadowCoord( vertexInput );
	#endif
	output.fogFactor=ComputeFogFactor( output.positionCS.z);
				
	return output;
}
half4 Frag(VertexOutput input): SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );
	#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)  || defined(_NEED_POS_WS)
	float3 WorldPosition=input.positionWS;
	#endif
	float4 ShadowCoords = float4( 0, 0, 0, 0 );
	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
			ShadowCoords = input.ShadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
			ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
	#endif

	float2 uvMainTex = TRANSFORM_TEX(input.texcoord3, _BaseMap);
	float2 uvPannerTex=TRANSFORM_TEX(input.texcoord3, _PannerTex);
	float2 panner_PannerTex=PolarAndRotator(uvPannerTex,_PannerUVSpeedAndRota.z,_PannerUVSpeedAndRota.x,_PannerUVSpeedAndRota.y);

	float2 uvDissloveTex=TRANSFORM_TEX(input.texcoord3, _DissloveTex);
	float2 panner_DissloveTex=PolarAndRotator(uvDissloveTex,_DissloveUVSpeedAndRota.z,_DissloveUVSpeedAndRota.x,_DissloveUVSpeedAndRota.y);

	float disTexR=SAMPLE_TEXTURE2D(_DissloveTex,sampler_DissloveTex,panner_DissloveTex).r + 1.0;
				
	float4 uv4=float4(input.texcoord4.xy * float2(1,1)+float2(0,0),input.texcoord4.zw);
	float4 appenduv4=float4(_Main_U_Offset , _Main_V_Offset , _DissloveUVSpeedAndRota.w , _PannerUVSpeedAndRota.w);
	float4 lerpuv4=lerp(uv4,appenduv4,_Mode);
	float temp_output=lerpuv4.z * (1.0 + _Edgewidth);
	float oneSubHardNess=1.0- _Hardness;
	float2 uvMaskTex=TRANSFORM_TEX(input.texcoord3, _MaskMap);
	float2 panner_MaskTex=PolarAndRotator(uvMaskTex,_MaskUVSpeedAndRota.z,_MaskUVSpeedAndRota.x,_MaskUVSpeedAndRota.y);
	float4 maskNode=SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,panner_MaskTex);

	half3 viewDirWS =normalize( GetCameraPositionWS() - input.positionWS);
	float3 worldNormal=input.texcoord5.xyz;
	float fresnelNDotV=dot(worldNormal,viewDirWS);
	float fresnelNode=(0.0 + _FresnelIntensity * pow(abs(1.0 - fresnelNDotV ),_FresnelWidth));

	float2 panner_MainTex=float2(0,0);
	#if defined(_ADDOrBLEND)
	float  clamp0=clamp( 0.0 , 0.0001 , 0.0 );
	float  tempFrac=frac((_TimeParameters.x + clamp0)/1.0);
	float2 temp_outputFrac0=float2(tempFrac,1.0-tempFrac);
	float2 tempMain=uvMainTex/float2(1.0,1.0) + floor(float2(1.0,1.0) * temp_outputFrac0) / float2(1.0,1.0);
	float2 tempAppenduv=float2(lerpuv4.x + tempMain.x , tempMain.y + lerpuv4.y );
    panner_MainTex=PolarAndRotator(tempAppenduv,_MainUVSpeedAndRota.z,_MainUVSpeedAndRota.x,_MainUVSpeedAndRota.y);
	#else
    panner_MainTex=PolarAndRotator(uvMainTex,_MainUVSpeedAndRota.z,_MainUVSpeedAndRota.x,_MainUVSpeedAndRota.y);
	#endif

	float4 appendnode=SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,(panner_MainTex + SAMPLE_TEXTURE2D(_PannerTex,sampler_PannerTex, panner_PannerTex).r * lerpuv4.w));
	float4 lerpResult=lerp(_EdgeColor,(_BaseColor * appendnode * input.color),saturate(((disTexR-(temp_output * (1.0 + oneSubHardNess)))-_Hardness)/oneSubHardNess));

	float Alpha = 1;
#if defined(_ADDOrBLEND) && defined(_FresnelBlend_On)
	float3 Color = (saturate((((disTexR - ((temp_output - _Edgewidth) * (1.0 + oneSubHardNess))) - _Hardness) / (oneSubHardNess))) * _BaseColor.a * appendnode.a * input.color.a * (maskNode.r * maskNode.a * _MaskUVSpeedAndRota.w) * lerpResult + _FresnelColor * fresnelNode).rgb;
#elif !defined(_ADDOrBLEND) && defined(_FresnelBlend_On)
	float3 Color = (_FresnelColor * fresnelNode + lerpResult).rgb;
#else 
	float3 Color = (_FresnelColor * fresnelNode).rgb;
#endif


#if !defined(_ADDOrBLEND) &&  defined(_FresnelBlend_On)
	Alpha = saturate(saturate(((disTexR - (temp_output - _Edgewidth) * (1.0 + oneSubHardNess)) - _Hardness) / oneSubHardNess) * _BaseColor.a * appendnode.a * input.color.a * maskNode.r * maskNode.a * _MaskUVSpeedAndRota.w);
#elif !defined(_ADDOrBLEND) && !defined(_FresnelBlend_On)
	Alpha = saturate(((1 - (temp_output - _Edgewidth) * (1.0 + oneSubHardNess)) - _Hardness) / oneSubHardNess);
#endif

	float AlphaClipThreshold = 0.5;

	#ifdef _ALPHATEST_ON
		clip( Alpha - AlphaClipThreshold );
	#endif

	return half4(Color, Alpha);
    
}
#endif 