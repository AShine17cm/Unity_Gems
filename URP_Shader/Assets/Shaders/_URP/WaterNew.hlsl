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
	float  eyeDepth     :TEXCOORD7;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
//=============================================================
	CBUFFER_START(UnityPerMaterial)


	uniform float4 _DeepWaterColor;
	uniform float _Refraction;
	uniform float _WaveSpeed;
	uniform float _NormalTiling;
	uniform float _NormalStrength;
    uniform float _LightWrapping;
	uniform float4 _MainColor;
	uniform float _Density;
	uniform float _Fade;
	uniform float _MediumTilingDistance;
	uniform float _DistanceFade;
	uniform float _FarTilingDistance;
	uniform float _Distortion;
	uniform float _RealtimeReflectionIntensity;
	uniform float _FoamBlend;

	uniform float _FoamContrast;
	uniform float4 _FoamColor;
	uniform float _FoamIntensity;
	uniform float _FoamVisibility;
	uniform float _Gloss;
	uniform float _Specular;
	uniform float4 _SpecularColor;
	uniform float _DepthTransparency;
	uniform float _TransparencyFade;

	//uniform float _RippleStrength;
	//uniform float _PhysicalNormalStrength;
	//-------------------------------------------
	CBUFFER_END

	TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
	TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
	TEXTURE2D(_NormalTexture);SAMPLER(sampler_NormalTexture);	 float4 _NormalTexture_ST;
	TEXTURE2D(_ReflectionTex);SAMPLER(sampler_ReflectionTex);	 float4 _ReflectionTex_ST;


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
	o.eyeDepth=-TransformWorldToView(o.worldPos).z;
	//o.VertexSHFogCoord.a=ComputeFogFactor(vertexInput.positionCS.z);
//	OUTPUT_SH(o.normalWS.xyz,o.VertexSHFogCoord.rgb);
	return o;
}


//float4 CalulateWaveUV(float percent,float NormalStrength,float2 BaseUV)
//{
//	float2 uv =BaseUV * _NormalTiling * percent;
//	float2 uvSpeed = (float2(_WaveSpeed * percent , 0.0));
//	float2 pannerUV1=(_Time.y * uvSpeed  + uv );

//	float cos180 = cos( radians( 180.0 ) );
//	float sin180 = sin( radians( 180.0 ) );
//	float2 rotator=mul(uv - float2( 0.5,0.5 ) , float2x2( cos180 , -sin180 , sin180 , cos180 )) + float2( 0.5,0.5 );
//	float2 pannerUV2=_Time.y * uvSpeed + rotator;
//	float3 WaveUV=lerp( float3(0,0,1) , ( UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture, sampler_NormalTexture, pannerUV1 ) ) + UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture,sampler_NormalTexture, pannerUV2 ) ) ) , NormalStrength);
//	float4 NormalUV=float4( WaveUV , 0.0 );
//	return NormalUV;
//}
float3 GetWaveUV(float percent,float NormalStrength,float2 BaseUV )
{
	float2 uv =BaseUV * _NormalTiling * percent;
	float2 uvSpeed = (float2(_WaveSpeed * percent , 0.0));
	float2 pannerUV1=(_Time.y * uvSpeed  + uv );

	float cos180 = cos( radians( 180.0 ) );
	float sin180 = sin( radians( 180.0 ) );
	float2 rotator=mul(uv - float2( 0.5,0.5 ) , float2x2( cos180 , -sin180 , sin180 , cos180 )) + float2( 0.5,0.5 );
	float2 pannerUV2=_Time.y * uvSpeed + rotator;
	float3 WaveUV=lerp( float3(0,0,1) , ( UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture,sampler_NormalTexture, pannerUV1 ) ) + UnpackNormal( SAMPLE_TEXTURE2D( _NormalTexture,sampler_NormalTexture, pannerUV2 ) ) ) , NormalStrength);
		
	return WaveUV;
}


float4 frag(v2f i) : SV_Target
{

	float3 worldPos=i.worldPos;
	float3 worldNormal=i.normalWS;
	float3 worldTangent=i.tangentWS;
	float3 worldBitangent=i.bitangentWS;
	float3x3 worldToTangent=float3x3(worldTangent,worldBitangent,worldNormal);
	float4 screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
	float4 ScreenPosNorm = screenPos / screenPos.w;

	float2 NormalSign=float2(sign(worldNormal).y,1.0);
	float2 BaseUV=NormalSign * worldPos.xz;
	float3 WavesCloseUV=GetWaveUV(1.0,_NormalStrength,BaseUV);
	float depth=SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,ScreenPosNorm.xy ).r;
	float eyeDepth = LinearEyeDepth(depth,_ZBufferParams);
	float distanceDepth=saturate(( eyeDepth - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( 0.1 ));
	float2 refraction = ( (WavesCloseUV).xy * _Refraction * distanceDepth );
	float4 screenColor=SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, (ScreenPosNorm).xy + ( float2( 0.2,0 ) * refraction ) );
	float3 LightWrapVector = (( _LightWrapping * 0.5 )).xxx;
	float4 NormalsCloseUV = ( float4( WavesCloseUV , 0.0 ) );
	float normalStrengthClose = lerp( _NormalStrength , ( _NormalStrength / 20.0 ) , saturate( pow( ( distance(worldPos , GetCameraPositionWS() ) / _MediumTilingDistance ) , _DistanceFade ) ));
	float3 WavesMediumUV=GetWaveUV(1.0/10.0,normalStrengthClose,BaseUV);
	float4 NormalsMediumUV = ( float4( WavesMediumUV , 0.0 ));
	float4 LerpCoseToMedium = lerp( NormalsCloseUV , NormalsMediumUV , saturate( pow( ( distance( worldPos , GetCameraPositionWS()  ) / _MediumTilingDistance ) , _DistanceFade ) ));
	float normalStrengthMedium = lerp( normalStrengthClose , ( normalStrengthClose / 20.0 ) , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / _FarTilingDistance ) , _DistanceFade ) ));
	float3 WavesFarUV=GetWaveUV(1.0/30.0,normalStrengthMedium,BaseUV);
	float4 NormalsFarUV= float4( WavesFarUV , 0.0 );
	float4 LerpMediumToFar = lerp( LerpCoseToMedium , NormalsFarUV, saturate( pow( ( distance( worldPos , GetCameraPositionWS()) / _FarTilingDistance ) , _DistanceFade ) ));
	float3 WorldNormalUV = (float3(( ( LerpMediumToFar.xy * NormalSign ) + (worldNormal).xz ) ,  (worldNormal).y));
	float3 worldToTangentUV = normalize( mul( worldToTangent, (WorldNormalUV).xzy) );

	float3 appendResult735 = (float3(worldToTangentUV.x , worldToTangentUV.y , 1));
	float3 CurrentNormal = normalize( appendResult735  );	

	float3 ase_worldlightDir = normalize(TransformObjectToWorld ( worldPos ) );

	float3 normalizeWorldLightDir = normalize( ase_worldlightDir );	

	float NDotL = dot( CurrentNormal , ase_worldlightDir );

	float4 ase_lightColor = _MainLightColor;

	float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );

	float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;

	float2 pseudoRefraction484 = ( (ase_grabScreenPosNorm).xy + ( _Refraction * (worldToTangentUV).xy ) );

	float4 screenColor146 = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,pseudoRefraction484);

	float Depth = ( eyeDepth - i.eyeDepth );

	float3 appendResult258 = (float3(Depth , Depth , Depth));

	float3 rampColor = clamp( (float3( 1,1,1 ) + appendResult258 * (float3( 0,0,0 ) - float3( 1,1,1 )) / (( _MainColor * ( 1.0 / _Density ) ).rgb /*- float3(0,0,0)*/)) , float3( 0,0,0 ) , float3( 1,1,1 ) );
	
	float3 fadePower = (_Fade).xxx;
	float4 blendOpDest = ( screenColor146 * float4( pow( rampColor , fadePower ) , 0.0 ) );

	float3 normalizePlaneNormal = normalize( float3(0,1,0) );

	float4 waterColor = ( saturate( ( _DeepWaterColor + blendOpDest ) ));

	float4 realtimeReflection = SAMPLE_TEXTURE2D( _ReflectionTex, sampler_ReflectionTex,( (ScreenPosNorm).xy + ( (LerpMediumToFar).xy * _Distortion ) ) );

	float3 worldviewDir=normalize(GetCameraPositionWS()-worldPos );

	float3x3 tangentToWorldFast = float3x3(worldTangent.x,worldBitangent.x,worldNormal.x,
											   worldTangent.y,worldBitangent.y,worldNormal.y,
											   worldTangent.z,worldBitangent.z,worldNormal.z);
	
    float fresnelNdotV = dot( mul(tangentToWorldFast,worldToTangentUV), worldviewDir );

	float fresnelNode = saturate( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV, 2.0 ) );

	float4 lerpResult1377 = lerp( waterColor , realtimeReflection , ( fresnelNode * _RealtimeReflectionIntensity ));
	float3 appendResult776 = (float3(( worldToTangentUV * _Distortion ).x , 0.0 , 1.0));

	float distanceDepth313 = saturate( ( eyeDepth - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( _FoamBlend ) );


	float3 temp_cast_11 = (_FoamContrast).xxx;
	float3 temp_cast_12 = (( 1.0 - _FoamContrast )).xxx;
	float2 _Vector2 = float2(0,1);
	float3 temp_cast_13 = (_Vector2.x).xxx;
	float3 temp_cast_14 = (_Vector2.y).xxx;
	float4 temp_output_319_0 = ( ( 1.0 - distanceDepth313 ) * ( float4( (temp_cast_13 + (- temp_cast_11) * (temp_cast_14 - temp_cast_13) / (temp_cast_12 - temp_cast_11)) , 0.0 ) * _FoamColor * _FoamIntensity * -1.0 ) );

	float4 foam406 = ( temp_output_319_0 * temp_output_319_0 );
	
	float4 foamyWater490 = ( lerpResult1377 + ( foam406 * _FoamVisibility ) );

	//float clampResult100_g659 = clamp( ase_worldlightDir.y , ( length( (UNITY_LIGHTMODEL_AMBIENT).rgb ) / 3.0 ) , 1.0 );

	float3 diffuseColor131_g659 = ( ( ( max( ( LightWrapVector + ( ( 1.0 - LightWrapVector ) * NDotL ) ) , float3(0,0,0) ) * ase_lightColor.rgb ) * foamyWater490.rgb )/* * clampResult100_g659*/ );

	float3 HalfDirection = normalize( ( normalizeWorldLightDir + worldviewDir ) );

	float dotResult32_g659 = dot( HalfDirection , CurrentNormal );

	float SpecularPower14_g659 = exp2( ( ( _Gloss * 10.0 ) + 1.0 ) );

	float distanceDepth402 = saturate( abs( ( eyeDepth - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( 0.2 ) ) );

	float4 specularity504 = ( ( distanceDepth402 * _Specular ) * _SpecularColor );

	float3 specularFinalColor42_g659 = ( ase_lightColor.rgb * pow( max( dotResult32_g659 , 0.0 ) , SpecularPower14_g659 ) * specularity504.rgb );

	float3 diffuseSpecular132_g659 = ( diffuseColor131_g659 + specularFinalColor42_g659 );

	float distanceDepth261 = saturate( ( eyeDepth - LinearEyeDepth( ScreenPosNorm.z ,_ZBufferParams) ) / ( _DepthTransparency ) );

	float opacity508 = pow( distanceDepth261 , _TransparencyFade );

	float4 lerpResult87_g659 = lerp( screenColor , float4( diffuseSpecular132_g659 , 0.0 ) , opacity508);
	float4 finalColor;
	finalColor.rgb = ( lerpResult87_g659 ).rgb;
	finalColor.a = 1;
	return finalColor;
	// half3 ambient =_GlossyEnvironmentColor;
	//return float4(   ambient,1);

//	float3 appendNormal = (float3(( ( (normalizePlaneNormal).xy * NormalSign ) + WorldNormalXZ ) , WorldNormalY));
//	float3 worldToTangentDir6 = normalize( mul( worldToTangent, (appendNormal).xzy) );

//	float3 lerpResult1544 = lerp( ( worldToTangentDir6 ) , float3(0,0,1) , saturate( pow( ( distance( worldPos , GetCameraPositionWS() ) / 10.0 ) , 0.5 ) ));

//	float3 lerpResult1546 = lerp( float3(0,0,1) , lerpResult1544 , _PhysicalNormalStrength);

//	float3 appendResult1424 = (float3(( worldToTangentDir.x + lerpResult1419.x + lerpResult1546.x ) , ( worldToTangentDir.y + lerpResult1419.y + lerpResult1546.y ) , worldToTangentDir.z));

	
////	float refraction = ( _Refraction * 0.2 );
	
//	float2 pseudoRefraction484 = ( (ScreenPosNorm).xy + ( refraction * (appendResult1424).xy ) );
//	float4 screenColor=SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,pseudoRefraction484);

	
	
    
//	 float fresnel = (0.05 * pow( 1.0 - fresnelNdotV, 10.0 ) );

//	 #ifdef _ISRender_Off
//	  clip(_DeepWaterColor.a - 0.5);
//	 float4 finalColor=float4(_DeepWaterColor.rgb,0);
//	 #else
//	 float4 finalColor = lerp( _DeepWaterColor , screenColor, saturate( fresnel ));
//	 #endif
//	 float csz=i.vertex.z * i.vertex.w;
//	 real fogFactor=ComputeFogFactor(csz);
//	 finalColor.rgb=MixFog(finalColor.rgb,fogFactor);
//	 return float4( finalColor.rgb,finalColor.a);




}


#endif
