#ifndef URP_WATER_INCLUDED
#define URP_WATER_INCLUDED
//=============================================================
struct appdata
{
	float4 vertex  : POSITION;
	float3 normal  : NORMAL;
	float4 tangent : TANGENT;
	float2 uv      : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	float4 vertex                   :SV_POSITION;
	float2 uv                       :TEXCOORD0;
	float3 worldPos                 :TEXCOORD1;
	float4 normalWS                 :TEXCOORD2;
	float4 tangentWS                :TEXCOORD3;
	float4 bitangentWS              :TEXCOORD4;
	//float4 VertexSHFogCoord         :TEXCOORD5;

	float4 screenPos    :TEXCOORD6;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
//=============================================================
	CBUFFER_START(UnityPerMaterial)


	uniform float4 _DeepWaterColor;
	uniform float _Refraction;
	uniform float _WaveSpeed;
	uniform float _NormalTiling;
	uniform float _NormalStrength;
	uniform float _MediumTilingDistance;
	uniform float _DistanceFade;
	uniform float _FarTilingDistance;


	uniform float _RippleStrength;
	uniform float _PhysicalNormalStrength;
	//-------------------------------------------
	CBUFFER_END

	TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
	TEXTURE2D(_NormalTexture);SAMPLER(sampler_NormalTexture);	 float4 _NormalTexture_ST;


//=============================================================
inline float4 ASE_ComputeGrabScreenPos( float4 pos )
{
	#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
	#else
	float scale = 1.0;
	#endif
	float4 o = pos;
	o.y = pos.w * 0.5f;
	o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
	return o;
}

v2f vert(appdata v)
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
	VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
	o.vertex = vertexInput.positionCS;				   
	o.worldPos =vertexInput.positionWS;
	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	o.uv.xy  = TRANSFORM_TEX(v.uv, _NormalTexture);
	o.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    o.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    o.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
			
	//得到对应被抓取屏幕图像的采样坐标
	
	o.screenPos = ComputeScreenPos(o.vertex);
	
	//o.VertexSHFogCoord.a=ComputeFogFactor(vertexInput.positionCS.z);
//	OUTPUT_SH(o.normalWS.xyz,o.VertexSHFogCoord.rgb);
	return o;
}


float4 CalulateWaveUV(float percent,float NormalStrength,float2 BaseUV)
{
	float2 uv =BaseUV * _NormalTiling * percent;
	float2 uvSpeed = (float2(_WaveSpeed * percent , 0.0));
	float2 pannerUV1=(_Time.y * uvSpeed  + uv );

	float cos180 = cos( radians( 180.0 ) );
	float sin180 = sin( radians( 180.0 ) );
	float2 rotator=mul(uv - float2( 0.5,0.5 ) , float2x2( cos180 , -sin180 , sin180 , cos180 )) + float2( 0.5,0.5 );
	float2 pannerUV2=_Time.y * uvSpeed + rotator;
	float3 WaveUV=lerp( float3(0,0,1) , ( UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture, sampler_NormalTexture, pannerUV1 ) ) + UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture,sampler_NormalTexture, pannerUV2 ) ) ) , NormalStrength);
	float4 NormalUV=float4( WaveUV , 0.0 );
	return NormalUV;
}

float4 frag(v2f i) : SV_Target
{

	float3 worldPos=i.worldPos;
	float3 worldNormal=i.normalWS;
	float3 worldTangent=i.tangentWS;
	float3 worldBitangent=i.bitangentWS;
	float3x3 worldToTangent=float3x3(worldTangent,worldBitangent,worldNormal);
	float2 NormalSign=float2(sign(worldNormal).y,1.0);
	float2 BaseUV=NormalSign * worldPos.xz;
	float4 NormalUV1=CalulateWaveUV(1.0,_NormalStrength,BaseUV);
	float  normalStrengthMedium = lerp( _NormalStrength , ( _NormalStrength / 20.0 ) , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / _MediumTilingDistance ) , _DistanceFade ) ));
	float4 NormalUV2=CalulateWaveUV(1/10.0,normalStrengthMedium,BaseUV);
	float4 lerp1To2 = lerp( NormalUV1 , NormalUV2 , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / _MediumTilingDistance ) , _DistanceFade ) ));
	float  normalStrengthFar = lerp( normalStrengthMedium , ( normalStrengthMedium / 20.0 ) , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / _FarTilingDistance ) , _DistanceFade ) ));
	float4 NormalUV3=CalulateWaveUV(1/30.0,normalStrengthFar,BaseUV);
	float4 lerp2To3 = lerp( lerp1To2,NormalUV3 , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / _FarTilingDistance ) , _DistanceFade ) ));
	float2 WorldNormalXZ = (worldNormal).xz;
	float WorldNormalY =  (worldNormal).y;
	float3 FinalNormal = (float3(( ( (lerp2To3.rgb).xy * NormalSign ) + WorldNormalXZ ) , WorldNormalY));
	float3 worldToTangentDir = normalize( mul( worldToTangent, (FinalNormal).xzy) );
	float3 lerpResult1419 = lerp( float3(0,0,1) ,  float3(0,0,1) , _RippleStrength);
			
	float3 normalizePlaneNormal = normalize( float3(0,1,0) );

	float3 appendNormal = (float3(( ( (normalizePlaneNormal).xy * NormalSign ) + WorldNormalXZ ) , WorldNormalY));
	float3 worldToTangentDir6 = normalize( mul( worldToTangent, (appendNormal).xzy) );

	float3 lerpResult1544 = lerp( ( worldToTangentDir6 ) , float3(0,0,1) , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / 10.0 ) , 0.5 ) ));

	float3 lerpResult1546 = lerp( float3(0,0,1) , lerpResult1544 , _PhysicalNormalStrength);

	float3 appendResult1424 = (float3(( worldToTangentDir.x + lerpResult1419.x + lerpResult1546.x ) , ( worldToTangentDir.y + lerpResult1419.y + lerpResult1546.y ) , worldToTangentDir.z));

	float4 screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );	
	float refraction = ( _Refraction * 0.2 );
	float4 ScreenPosNorm = screenPos / screenPos.w;
	float2 pseudoRefraction484 = ( (ScreenPosNorm).xy + ( refraction * (appendResult1424).xy ) );
	float4 screenColor=SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,pseudoRefraction484);

	float3 worldviewDir=normalize(GetCameraPositionWS()-worldPos );
	float3x3 tangentToWorldFast = float3x3(worldTangent.x,worldBitangent.x,worldNormal.x,
											   worldTangent.y,worldBitangent.y,worldNormal.y,
											   worldTangent.z,worldBitangent.z,worldNormal.z);
     float fresnelNdotV = dot( mul(tangentToWorldFast,appendResult1424), worldviewDir );
	 float fresnel = (0.05 * pow( 1.0 - fresnelNdotV, 10.0 ) );

	 #ifdef _ISRender_Off
	  clip(_DeepWaterColor.a - 0.5);
	 float4 finalColor=float4(_DeepWaterColor.rgb,0);
	 #else
	 float4 finalColor = lerp( _DeepWaterColor , screenColor, saturate( fresnel ));
	 #endif
	 float csz=i.vertex.z * i.vertex.w;
	 real fogFactor=ComputeFogFactor(csz);
	 finalColor.rgb=MixFog(finalColor.rgb,fogFactor);
	 return float4( finalColor.rgb,finalColor.a);




}


#endif
