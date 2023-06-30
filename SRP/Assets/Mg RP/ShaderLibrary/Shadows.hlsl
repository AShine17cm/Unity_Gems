#ifndef MG_SHADOWS_INCLUDED
#define MG_SHADOWS_INCLUDED

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 1

//TEXTURE2D(_DirectionalShadowAtlas);
//SAMPLER(sampler_DirectionalShadowAtlas);

TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_MgShadows)
float4x4 _DirectionalShadowMatrices;
CBUFFER_END

float SampleDirectionalShadowAtlas(float3 positionSTS) {
	return SAMPLE_TEXTURE2D_SHADOW(
		_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS
	);
}
float GetDirectionalShadowAttenuation(Surface surfaceWS) {
	float3 positionSTS = mul(
		_DirectionalShadowMatrices,
		float4(surfaceWS.position, 1.0)
	).xyz;
	float shadow = SampleDirectionalShadowAtlas(positionSTS);
	return shadow;
}

#endif
