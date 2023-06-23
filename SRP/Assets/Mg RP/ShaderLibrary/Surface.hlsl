#ifndef MG_SURFACE_INCLUDED
#define MG_SURFACE_INCLUDED

struct Surface 
{
	float3 normal;
	float3 viewDir;
	float3 color;
	float alpha;

	//BRDF
	float metallic;
	float smoothness;
};

#endif