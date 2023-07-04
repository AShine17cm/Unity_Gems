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

struct v2f_H
{
	float4 vertex                   :SV_POSITION;
	float2 uv                       :TEXCOORD0;
	float3 worldPos                 :TEXCOORD1;
	float4 normalWS                 :TEXCOORD2;
	float4 tangentWS                :TEXCOORD3;
	float4 bitangentWS              :TEXCOORD4;
	float4 VertexSHFogCoord         : TEXCOORD5;

	float4 screenPos    :TEXCOORD6;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct v2f_L
{
	float4 vertex                   :SV_POSITION;
	float2 uv                       :TEXCOORD0;
	float3 worldPos                 :TEXCOORD1;
	float4 normalWS                 :TEXCOORD2;
	float4 tangentWS                :TEXCOORD3;
	float4 bitangentWS              :TEXCOORD4;
	float4 VertexSHFogCoord         : TEXCOORD5;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};
//=============================================================
	CBUFFER_START(UnityPerMaterial)

	float4 _DeepWaterColor;
	half4 _SpecularColor;
	half _FresnelPower;
	half _Smoothness;
	half _WaveAngle;
	float4 _Direction;
	half _WaveXSpeed,_WaveYSpeed;
	half _Reflection;
    float4 _ReflectColor;
	half _CausticRange;
	float4 _ShallowColor;
	half _DepthRange;
	half _Distortion;
	float4 _Caustic1_ST,_Caustic2_ST,_CausticSpeed;
	half _FoamRange,_WaterRange,_WaveRange;
	half _NoiseRange;
	half _FoamWaveDelta;
	half _FoamSpeed;
	half _MaxDistance;
	half _MinDistance;

		
		
		
	//-------------------------------------------
	CBUFFER_END
	TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);	
	TEXTURE2D(_SelfDepthTexture2); SAMPLER(sampler_SelfDepthTexture2);
	TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
	TEXTURE2D(_CameraColorTexture);SAMPLER(sampler_CameraColorTexture);

	TEXTURE2D(_CausticTex);SAMPLER(sampler_CausticTex);	 
	TEXTURE2D(_FoamTex);SAMPLER(sampler_FoamTex);	 
	TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);	 

	TEXTURE2D(_WaveMap);SAMPLER(sampler_WaveMap);float4 _WaveMap_ST;
	TEXTURECUBE(_Cubemap);	SAMPLER(sampler_Cubemap);
	TEXTURE2D(_WaterNoiseTex); SAMPLER(sampler_WaterNoiseTex);float4 _WaterNoiseTex_ST;
	

//=============================================================
v2f_H vertH(appdata v)
{
	v2f_H o;
	UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
	VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
	o.vertex = vertexInput.positionCS;				   
	o.worldPos =vertexInput.positionWS;
	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	o.uv.xy  = TRANSFORM_TEX(v.uv, _WaveMap);
	o.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    o.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    o.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
			
	//得到对应被抓取屏幕图像的采样坐标
	
	o.screenPos = ComputeScreenPos(o.vertex);
	
	o.VertexSHFogCoord.a=ComputeFogFactor(vertexInput.positionCS.z);
	OUTPUT_SH(o.normalWS.xyz,o.VertexSHFogCoord.rgb);
	return o;
}
v2f_L vertL(appdata v)
{
	v2f_L o;
	UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
	VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
	o.vertex = vertexInput.positionCS;				   
	o.worldPos =vertexInput.positionWS;
	half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
	o.uv.xy  = TRANSFORM_TEX(v.uv, _WaveMap);
	o.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    o.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    o.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
	
	o.VertexSHFogCoord.a=ComputeFogFactor(vertexInput.positionCS.z);
	OUTPUT_SH(o.normalWS.xyz,o.VertexSHFogCoord.rgb);
	return o;
	}
void InitializeInputData(v2f_H input, half3 normalTS, out InputData inputData)
{
	inputData = (InputData)0;
            
	inputData.positionWS = input.worldPos;
            
	half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
	inputData.normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	viewDirWS = SafeNormalize(viewDirWS);
	inputData.viewDirectionWS = viewDirWS;
	inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	inputData.fogCoord = input.VertexSHFogCoord.a;
	inputData.bakedGI = SampleSHPixel(input.VertexSHFogCoord.rgb, inputData.normalWS);
}
void InitializeInputData2(v2f_L input, half3 normalTS, out InputData inputData)
{
	inputData = (InputData)0;
            
	inputData.positionWS = input.worldPos;
            
	half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
	inputData.normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	viewDirWS = SafeNormalize(viewDirWS);
	inputData.viewDirectionWS = viewDirWS;
	inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	inputData.fogCoord = input.VertexSHFogCoord.a;
	inputData.bakedGI = SampleSHPixel(input.VertexSHFogCoord.rgb, inputData.normalWS);
}
half2 rotateUV(float2 uv,float angle)
{
	float cosAngle=cos(angle);
	float sinAngle=sin(angle);
	float2x2 rotateM=float2x2(cosAngle,-sinAngle,sinAngle,cosAngle);
	return mul(rotateM,uv);
}
float DecodeFloatRGBA(float4 enc)
{
	float4 kDecodeDot = float4(1.0, 1 / 255.0, 1 / 65025.0, 1 / 160581375.0);
	return dot(enc, kDecodeDot);
}
float4 fragMedium(v2f_H i) : SV_Target
{
				   
	//---------------------法线扰动--------------------------------------------
	float2 uv0=rotateUV(i.uv,_WaveAngle);
	float2 animUV1=uv0.xy+float2(normalize( _Direction.xy))*_WaveXSpeed*_Time.y;
	float2 animUV2=uv0.xy+float2(normalize( _Direction.zw))*_WaveYSpeed*_Time.y;
	float4 wavecolor=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy + animUV1.xy);
	wavecolor*=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy*10 + animUV2.xy);
	float3 bump1 = UnpackNormal(wavecolor).rgb;
	float3 bump = normalize(bump1);		
	InputData inputData;
    InitializeInputData(i, bump, inputData);
	Light light = GetMainLight(inputData.shadowCoord);
	
	
	//------------------计算深度--------------------------------------------
		float depth = 0;
	float4 depthcolor = SAMPLE_TEXTURE2D(_SelfDepthTexture2, sampler_SelfDepthTexture2, i.screenPos.xy / i.screenPos.w);
	depth = DecodeFloatRGBA(depthcolor);
	float3 worldPos = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);
	//------------------当前自己的位置-------------------------------------
	float dis = length(worldPos.xyz - _WorldSpaceCameraPos.xyz);
	float disvalue = saturate((dis - _MinDistance) / _MaxDistance);
	float sceneZ = depth;
	//---------------------
	float thisZ = i.screenPos.z / i.screenPos.w;
	thisZ = Linear01Depth(thisZ, _ZBufferParams);

	float deltaDepth = max(0, sceneZ - thisZ)*_ProjectionParams.z;
	float alpha = saturate( min(_DepthRange, deltaDepth) / _DepthRange);
	float4 waterColor = lerp(_ShallowColor, _DeepWaterColor, alpha);
	// Compute the offset in tangent space

	//------------------------焦散----------------------------------------
	half2 uv1=i.uv*_Caustic1_ST.xy+_Caustic1_ST.zw;
	half2 uv2=i.uv*_Caustic2_ST.xy+_Caustic2_ST.zw;

	uv1+=_CausticSpeed.xy*_Time.y;
	uv2+=_CausticSpeed.zw*_Time.y;

	half3 causticColor1=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,uv1).rgb;
	half3 causticColor2=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,uv2).rgb;

	half fade=saturate( min(_CausticRange, deltaDepth) /_CausticRange);
	half3 causticColor=lerp(min(causticColor1, causticColor2)*0.5,float3(0,0,0),fade);

	//---------------------------折射--------------------------------------
	float2 offset = bump.xy * _Distortion ;
	i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
	half3 refrCol = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.screenPos.xy / i.screenPos.w).rgb ;
	
		
	//----------------------反射，采样环境贴图--------------------------------
	half3 attenuatedLightColor = light.color* waterColor.rgb * (light.distanceAttenuation * light.shadowAttenuation);
                
    float3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 H = normalize(light.direction + inputData.viewDirectionWS);
	half3 specularColor = attenuatedLightColor * _SpecularColor.rgb * pow(saturate(dot(inputData.normalWS, H)), _Smoothness);
                   
	float3 reflDir = reflect(-inputData.viewDirectionWS, inputData.normalWS);
	float3 reflCol = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflDir,7).rgb*_ReflectColor.rgb;
				
	half fresnel = Fresnel (inputData.normalWS, inputData.viewDirectionWS, _FresnelPower);
	
	alpha=lerp(0,waterColor.a,alpha);
	float3 col=lerp(refrCol,reflCol,disvalue);
	//diffuseColor=lerp(diffuseColor,reflCol,fresnel*_Reflection);
	diffuseColor*=col;
	diffuseColor+=specularColor;
	//diffuseColor+=causticColor;
	float3 finalColor=lerp(refrCol,diffuseColor,alpha);
	float csz=i.vertex.z * i.vertex.w;
	real fogFactor=ComputeFogFactor(csz);
	finalColor=MixFog(finalColor,fogFactor);
	return float4(finalColor, alpha);
}

float4 fragHigh(v2f_H i) : SV_Target
{
				   
	//---------------------法线扰动--------------------------------------------
	float2 uv0=rotateUV(i.uv,_WaveAngle);
	float2 animUV1=uv0.xy+float2(normalize( _Direction.xy))*_WaveXSpeed*_Time.y;
	float2 animUV2=uv0.xy+float2(normalize( _Direction.zw))*_WaveYSpeed*_Time.y;
	float4 wavecolor=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy + animUV1.xy);
	wavecolor*=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy*10 + animUV2.xy);
	float3 bump1 = UnpackNormal(wavecolor).rgb;
	float3 bump = normalize(bump1);		
	InputData inputData;
    InitializeInputData(i, bump, inputData);
	Light light = GetMainLight(inputData.shadowCoord);
	
	//------------------计算深度--------------------------------------------
	float depth = 0;

	float4 depthcolor = SAMPLE_TEXTURE2D(_SelfDepthTexture2, sampler_SelfDepthTexture2, i.screenPos.xy / i.screenPos.w);
	depth = DecodeFloatRGBA(depthcolor);
	//depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,i.screenPos.xy / i.screenPos.w).r;
	float3 worldPos = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);
	//------------------当前自己的位置-------------------------------------
	float dis = length(worldPos.xyz - _WorldSpaceCameraPos.xyz);
	float disvalue = saturate((dis - _MinDistance) / _MaxDistance);
	float sceneZ = depth;
	//---------------------
	float thisZ = i.screenPos.z / i.screenPos.w;
	thisZ = Linear01Depth(thisZ, _ZBufferParams);

	float deltaDepth = max(0, sceneZ - thisZ)*_ProjectionParams.z;
	float alpha = saturate( min(_DepthRange, deltaDepth) / _DepthRange);
	float4 waterColor = lerp(_ShallowColor, _DeepWaterColor, alpha);

	// Compute the offset in tangent space
	
	//------------------------焦散----------------------------------------
	half2 uv1=i.uv*_Caustic1_ST.xy+_Caustic1_ST.zw;
	half2 uv2=i.uv*_Caustic2_ST.xy+_Caustic2_ST.zw;

	uv1+=_CausticSpeed.xy*_Time.y;
	uv2+=_CausticSpeed.zw*_Time.y;

	float3 causticColor1=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,uv1).rgb;
	float3 causticColor2=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,uv2).rgb;

	float fade=saturate( min(_CausticRange, deltaDepth) /_CausticRange);
	float3 causticColor=lerp(min(causticColor1, causticColor2)*0.5,float3(0,0,0),fade);

	//---------------------------折射--------------------------------------
	float2 offset = bump.xy * _Distortion ;
	i.screenPos.xy = offset * i.screenPos.z + i.screenPos.xy;
	half3 refrCol = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, i.screenPos.xy / i.screenPos.w).rgb ;
	//--------------------------------波浪水花----------------------------
	float4 noiseColor = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv);

	float4 waveColor=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,float2(1-min(_FoamRange,deltaDepth)/_FoamRange + _WaveRange 
		+sin(_Time.x * _FoamSpeed + noiseColor.r * _NoiseRange),1)+offset);

		waveColor.rgb *= (1 - (sin(_Time.x*_FoamSpeed + noiseColor.r*_NoiseRange) + 1) / 2)*noiseColor.r;

		float4 waveColor2=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,float2(1-min(_FoamRange,deltaDepth)/_FoamRange + _WaveRange
		+sin(_Time.x*_FoamSpeed +_FoamWaveDelta + noiseColor.r*_NoiseRange),1)+offset);

		waveColor2.rgb *= (1 - (sin(_Time.x*_FoamSpeed +_FoamWaveDelta + noiseColor.r*_NoiseRange) + 1) / 2)*noiseColor.r;
		float water_A = 1-min(_WaterRange, deltaDepth)/_WaterRange;
		//half water_B = min(_ShoalRange, deltaDepth)/_ShoalRange;
		float3 waveColorCombine=waveColor.rgb+waveColor2.rgb;
	//----------------------反射，采样环境贴图--------------------------------
	half3 attenuatedLightColor = light.color* waterColor.rgb * (light.distanceAttenuation * light.shadowAttenuation);
                
    half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 H = normalize(light.direction + inputData.viewDirectionWS);
	half3 specularColor = attenuatedLightColor * _SpecularColor.rgb * pow(saturate(dot(inputData.normalWS, H)), _Smoothness);
                   
	float3 reflDir = reflect(-inputData.viewDirectionWS, inputData.normalWS);
	float3 reflCol = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflDir,7).rgb*_ReflectColor.rgb;
				
	half fresnel = Fresnel (inputData.normalWS, inputData.viewDirectionWS, _FresnelPower);
	
	alpha=lerp(0,waterColor.a,alpha);
	float3 finalColor=lerp(refrCol,reflCol,disvalue);
	diffuseColor*=finalColor;
	//diffuseColor=lerp(diffuseColor,reflCol,fresnel*_Reflection);
	diffuseColor+=specularColor;
	diffuseColor+=waveColorCombine*water_A;
	//alpha = saturate(alpha * (1 - disvalue) + disvalue);
	 float csz=i.vertex.z * i.vertex.w;
	 real fogFactor=ComputeFogFactor(csz);
	 diffuseColor=MixFog(diffuseColor,fogFactor);
	 return float4(diffuseColor.rgb, alpha);	
	// return float4(alpha, alpha, alpha, alpha);
}
float4 fragLow(v2f_L i) : SV_Target
{
				   
	//---------------------------法线扰动-------------------------------------
	float2 uv0=rotateUV(i.uv,_WaveAngle);
	float2 animUV1=uv0.xy+float2(normalize( _Direction.xy))*_WaveXSpeed*_Time.y;
	float2 animUV2=uv0.xy+float2(normalize( _Direction.zw))*_WaveYSpeed*_Time.y;
	float4 wavecolor=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy + animUV1.xy);
	wavecolor*=SAMPLE_TEXTURE2D(_WaveMap, sampler_WaveMap, i.uv.xy*10 + animUV2.xy);
	float3 bump1 = UnpackNormal(wavecolor).rgb;
	//float3 bump2 = UnpackNormal().rgb;
	float3 bump = normalize(bump1 /*+ bump2*/);		
	InputData inputData;
    InitializeInputData2(i, bump, inputData);
	Light light = GetMainLight(inputData.shadowCoord);

	float4 waterColor = _DeepWaterColor;
	
	half3 attenuatedLightColor = light.color* waterColor.rgb * (light.distanceAttenuation * light.shadowAttenuation);
                
    half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 H = normalize(light.direction + inputData.viewDirectionWS);
	half3 specularColor = attenuatedLightColor * _SpecularColor.rgb * pow(saturate(dot(inputData.normalWS, H)), _Smoothness);
                   
	float3 reflDir = reflect(-inputData.viewDirectionWS, inputData.normalWS);
	float3 reflCol = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflDir,7).rgb*_ReflectColor.rgb;
	half fresnel = Fresnel (inputData.normalWS, inputData.viewDirectionWS, _FresnelPower);
	//float fresnel = pow(saturate(1-dot(viewDir, Worldbump)), 4);
	float alpha=waterColor.a;
	diffuseColor=lerp(diffuseColor,reflCol,fresnel*_Reflection);
	diffuseColor+=specularColor;
	float3 finalColor=diffuseColor.rgb;
	float csz=i.vertex.z * i.vertex.w;
	real fogFactor=ComputeFogFactor(csz);
	finalColor=MixFog(finalColor,fogFactor);
	return  float4(finalColor, alpha);
}
//================================================================================================


#endif //URP_WATERINCLUDED
//------------------------------------------------------------------------------------