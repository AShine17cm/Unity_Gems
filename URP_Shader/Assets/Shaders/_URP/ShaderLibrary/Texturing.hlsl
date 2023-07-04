#ifndef URP_TEXTURING_INCLUDED
#define URP_TEXTURING_INCLUDED

#include "ImageAdjustment.hlsl"
#include "Util.hlsl"

void TextureCropping_float(float2 UVs, Texture2D T2D, SamplerState SS, float2 UpperLeftCorner, float2 LowerRightCorner, out float4 Cropped){
    float2 uv;
    UVCropping_float(UVs,UpperLeftCorner,LowerRightCorner, uv);
    Cropped = SAMPLE_TEXTURE2D(T2D, SS, uv);
}

void WorldAlignedTexture_float(Texture2D tex, SamplerState ss, float3 positionWS, float3 normalWS, float3 texSize, float contrast, out float4 rgba)
{
     positionWS /= -abs(texSize);
     float2 rb = positionWS.rb;
     float2 gb = positionWS.gb;
     float2 rg = positionWS.rg;
     
     float4 rbCol =  SAMPLE_TEXTURE2D(tex, ss, rb);
     float4 gbCol =  SAMPLE_TEXTURE2D(tex, ss, gb);
     float4 rgCol =  SAMPLE_TEXTURE2D(tex, ss, rg);
     
     float nX, nZ;
     CheapContrast_float(abs(normalWS.x), contrast, nX);
     CheapContrast_float(abs(normalWS.z), contrast, nZ);
     
     rgba = lerp(lerp(rbCol, gbCol, nX), rgCol, nZ);
}

void WorldAlignedNormal_float(Texture2D tex, SamplerState ss, float3 positionWS, float3 normalWS, float3 texSize, float contrast, out float3 rgb)
{
     positionWS /= -abs(texSize);
     float2 rb = positionWS.rb;
     float2 gb = positionWS.gb;
     float2 rg = positionWS.rg;
     
     float3 rbCol = UnpackNormal(SAMPLE_TEXTURE2D(tex, ss, rb));
     float3 gbCol = UnpackNormal(SAMPLE_TEXTURE2D(tex, ss, gb));
     float3 rgCol = UnpackNormal(SAMPLE_TEXTURE2D(tex, ss, rg));
     
     float nX, nZ;
     CheapContrast_float(abs(normalWS.x), contrast, nX);
     CheapContrast_float(abs(normalWS.z), contrast, nZ);
     
     float3 rbNormal = float3(-rbCol.r, rgCol.b* normalWS.y, -rbCol.g);
     float3 gbNormal = float3(normalWS.x * gbCol.b, -gbCol.r, -gbCol.g);
     float3 rgNormal = float3(-rgCol.rg, rgCol.b * normalWS.z);
     
     rgb = normalize(lerp(lerp(rbNormal, gbNormal, nX), rgNormal, nZ));
}

struct TriplanarUV {
	float2 x, y, z;
};


TriplanarUV GetTriplanarUV ( float3 positionWS, float3 normalWS, float3 scale) {
	TriplanarUV triUV;
	float3 p = positionWS * scale;
	triUV.x = p.zy;
	triUV.y = p.xz;
	triUV.z = p.xy;
	
	// Fix Mirrored Mapping
	if (normalWS.x < 0) {
		triUV.x.x = -triUV.x.x;
	}
	if (normalWS.y < 0) {
		triUV.y.x = -triUV.y.x;
	}
	if (normalWS.z >= 0) {
		triUV.z.x = -triUV.z.x;
	}
	
	triUV.x.y += 0.5;
	triUV.z.x += 0.5;
	return triUV;
}

float3 GetTriplanarWeights (float3 normalWS, float bendExpo=2, float bendOffset = 0.25) {
	float3 triW = saturate( abs(normalWS) - bendOffset);
	triW = pow(triW, bendExpo);
	return triW / (triW.x + triW.y + triW.z);
}

float3 BlendTriplanarNormal (float3 mappedNormal, float3 surfaceNormal) {
	float3 n;
	n.xy = mappedNormal.xy + surfaceNormal.xy;
	n.z = mappedNormal.z * surfaceNormal.z;
	return n;
}

void TriplanarSample_float(Texture2D tex, SamplerState ss, float3 positionWS, float3 normalWS, float3 texScale, float contrast, out float4 rgba)
{
    TriplanarUV triUV = GetTriplanarUV(positionWS, normalWS, texScale);
    float3 triW = GetTriplanarWeights(normalWS, contrast);
     
     float4 colX =  SAMPLE_TEXTURE2D(tex, ss, triUV.x);
     float4 colY =  SAMPLE_TEXTURE2D(tex, ss, triUV.y);
     float4 colZ =  SAMPLE_TEXTURE2D(tex, ss, triUV.z);
     rgba = colX * triW.x + colY * triW.y + colZ * triW.z;
}
void TriplanarSampleNormalSmooth_float(Texture2D tex, SamplerState ss, float3 positionWS, float3 normalWS, 
                                        float3 texScale, float contrast, out float3 rgb, out float smoothness)
{
     TriplanarUV triUV = GetTriplanarUV(positionWS, normalWS, texScale);
     float3 triW = GetTriplanarWeights(normalWS, contrast);
     
     float4 colX =  SAMPLE_TEXTURE2D(tex, ss, triUV.x);
     float4 colY =  SAMPLE_TEXTURE2D(tex, ss, triUV.y);
     float4 colZ =  SAMPLE_TEXTURE2D(tex, ss, triUV.z);
     
     smoothness = colX.a * triW.x + colY.a * triW.y + colZ.a * triW.z;
     
     colX =colX *2-1;
     colY =colY *2-1;
     colZ =colZ *2-1;
     
     // Fix Mirrored Mapping
     if(normalWS.x < 0){
        colX.x = - colX.x;
     }
     
     if(normalWS.y < 0){
        colY.x = - colY.x;
     }
     
     if(normalWS.z >= 0){
        colZ.x = - colZ.x;
     }
     
     float3 worldNormalX = BlendTriplanarNormal(colX.xyz, normalWS.zyx).zyx;
     float3 worldNormalY = BlendTriplanarNormal(colY.xyz, normalWS.xzy).xzy;
     float3 worldNormalZ = BlendTriplanarNormal(colZ.xyz, normalWS);
     
     rgb = normalize(worldNormalX* triW.x + worldNormalY* triW.y + worldNormalZ * triW.z);
}

void WorldAlignedNormalSmooth_float(Texture2D tex, SamplerState ss, float3 positionWS, float3 normalWS, 
                                    float3 texSize, float contrast, out float3 rgb, out float smoothness)
{
     positionWS /= -abs(texSize);
     float2 rb = positionWS.rb;
     float2 gb = positionWS.gb;
     float2 rg = positionWS.rg;
     
     float4 rbCol = SAMPLE_TEXTURE2D(tex, ss, rb);
     float4 gbCol = SAMPLE_TEXTURE2D(tex, ss, gb);
     float4 rgCol = SAMPLE_TEXTURE2D(tex, ss, rg);
     
     float nX, nZ;
     CheapContrast_float(abs(normalWS.x), contrast, nX);
     CheapContrast_float(abs(normalWS.z), contrast, nZ);
     smoothness = lerp(lerp(rbCol.a, gbCol.a, nX), rgCol.a, nZ);
     
     rbCol = rbCol*2-1;
     gbCol = gbCol*2-1;
     rgCol = rgCol*2-1;
    
     float3 rbNormal = float3(-rbCol.r, rgCol.b* normalWS.y, -rbCol.g);
     float3 gbNormal = float3(normalWS.x * gbCol.b, -gbCol.r, -gbCol.g);
     float3 rgNormal = float3(-rgCol.rg, rgCol.b * normalWS.z);
     
     rgb = normalize(lerp(lerp(rbNormal, gbNormal, nX), rgNormal, nZ));
}
#endif // URP_TEXTURING_INCLUDED