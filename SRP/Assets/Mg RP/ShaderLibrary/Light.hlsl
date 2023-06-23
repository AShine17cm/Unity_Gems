#ifndef MG_LIGHT_INCLUDED
#define MG_LIGHT_INCLUDED

#define MAX_DIR_LIGHT_COUNT 4

CBUFFER_START(_MgLight)
	int _DirLightCount;
	float4 _DirLightColors[MAX_DIR_LIGHT_COUNT];
	float4 _DirLightDirections[MAX_DIR_LIGHT_COUNT];
CBUFFER_END

struct Light 
{
	float3 color;
	float3 direction;
};
int GetDirLightCount() {
	return _DirLightCount;
}
Light GetDirLight(int index)
{
	Light light;
	light.color = _DirLightColors[index];
	light.direction = _DirLightDirections[index];
	return light;
}

#endif