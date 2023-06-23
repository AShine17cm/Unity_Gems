#ifndef MG_LIGHTING_INCLUDED
#define MG_LIGHTING_INCLUDED

float3 IncomingLight(Surface surface,Light light)//光照方程
{
	return saturate(dot(surface.normal, light.direction)) * light.color;
}

float3 GetLighting(Surface surface, BRDF brdf, Light light)//单个照明
{
	return IncomingLight(surface, light) * DirectBRDF(surface,brdf,light);
}

float3 GetLighting(Surface surface, BRDF brdf)
{
	float3 color = 0.0;
	for (int i = 0; i < GetDirLightCount(); i++)
	{
		color += GetLighting(surface,brdf, GetDirLight(i));
	}
	return color;
}


#endif