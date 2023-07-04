#ifndef URP_UTIL_INCLUDED
#define URP_UTIL_INCLUDED

half3 BendAngleCorrectedNormals(half3 baseNormal, half3 additionalNormal) {
    half baseZ = baseNormal.z + 1;
    half3 base = half3(baseNormal.xy, baseZ);   
    half3 additional = half3( -additionalNormal.xy,  additionalNormal.z);
    
    return dot(base, additional) * base - baseZ * additional;
}

// Returns > 0 if not clipped, < 0 if clipped based
// on the dither
// For use with the "clip" function
// pos is the fragment position in screen space from [0,1]
float isDithered(float2 pos, float alpha) {
    pos *= _ScreenParams.xy;

    // Define a dither threshold matrix which can
    // be used to define how a 4x4 set of pixels
    // will be dithered
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };

    int index = (uint(pos.x) % 4) * 4 + uint(pos.y) % 4;
    return alpha - DITHER_THRESHOLDS[index];
}

float isDithered(float2 pos, float alpha,float size) {
    pos *= _ScreenParams.xy;

    // Define a dither threshold matrix which can
    // be used to define how a 4x4 set of pixels
    // will be dithered
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };

    int index = (uint(pos.x) % size) * size + uint(pos.y) % size;
    return alpha - DITHER_THRESHOLDS[index] ;
}
float isDitheredleaf(float2 pos, float alpha) {
    pos *= _ScreenParams.xy;

    // Define a dither threshold matrix which can
    // be used to define how a 4x4 set of pixels
    // will be dithered
    float DITHER_THRESHOLDS[16] =
    {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
    float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
    //int index = [fmod(pos.x , 4)] *_RowAccess [fmod(pos.y, 4)];
    return alpha - DITHER_THRESHOLDS[fmod(pos.x ,4)] *_RowAccess [fmod(pos.y, 4)];
}
// Returns whether the pixel should be discarded based
// on the dither texture
// pos is the fragment position in screen space from [0,1]
float isDithered(float2 pos, float alpha, sampler2D tex, float scale) {
    pos *= _ScreenParams.xy;

    // offset so we're centered
    pos.x -= _ScreenParams.x / 2;
    pos.y -= _ScreenParams.y / 2;
    
    // scale the texture
    pos.x /= scale;
    pos.y /= scale;

	// ensure that we clip if the alpha is zero by
	// subtracting a small value when alpha == 0, because
	// the clip function only clips when < 0
    return alpha - tex2D(tex, pos.xy).r - 0.0001 * (1 - ceil(alpha));
}

// Helpers that call the above functions and clip if necessary
void ditherClip(float2 pos, float alpha) {
    clip(isDithered(pos, alpha));
}

void ditherClip(float2 pos, float alpha, sampler2D tex, float scale) {
    clip(isDithered(pos, alpha, tex, scale));
}


void SphereMaskC_float(float Coords, float Center, float Radius, float Hardness, out float Out)
{
    Out = 1 - saturate((distance(Coords, Center) - Radius) / (1 - Hardness));
}

void SphereMaskC_float(float2 Coords, float2 Center, float Radius, float Hardness, out float2 Out)
{
    Out = 1 - saturate((distance(Coords, Center) - Radius) / (1 - Hardness));
}

void SphereMaskC_float4(float4 Coords, float4 Center, float Radius, float Hardness, out float4 Out)
{
    Out = 1 - saturate((distance(Coords, Center) - Radius) / (1 - Hardness));
}

void UVCropping_float(float2 UVs, float2 UpperLeftCorner, float2 LowerRightCorner, out float2 CroppedUVs){
    CroppedUVs = (-UpperLeftCorner + UVs) /(LowerRightCorner - UpperLeftCorner);
}

void UVCroppingMask_float(float2 UVs, float2 UpperLeftCorner, float2 LowerRightCorner, float Hardness, out float2 CroppedUVs, out float CroppedMask){
    UVCropping_float(UVs, UpperLeftCorner, LowerRightCorner, CroppedUVs);
    float maskU, maskV;
    SphereMaskC_float(CroppedUVs.r, .5, 0.5, Hardness, maskU);
    SphereMaskC_float(CroppedUVs.g, .5, 0.5, Hardness, maskV);
    CroppedMask = maskU * maskV;
}

inline half3 GammaToLinearSpace (half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}

inline half3 LinearToGammaSpace (half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);

    // Exact version, useful for debugging.
    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));
}

float B2_Spline(float x) {
    float t = 3.0 * x;
    float b0 = step(0.0, t) * step(0.0, 1.0 - t);
    float b1 = step(0.0, t - 1.0) * step(0.0, 2.0 - t);
    float b2 = step(0.0, t - 2.0) * step(0.0, 3.0 - t);
    return 0.5 * (
        b0 * pow(t, 2.0) + 
        b1 * (-2.0 * pow(t, 2.0) + 6.0 * t - 3.0) + 
        b2 * pow(3.0 - t, 2.0)
    );
}

// Helper for intensityToColour
float h2rgb(float h) {
	if(h < 0.0) h += 1.0;
	if(h < 0.166666) return 0.1 + 4.8 * h;
	if(h < 0.5) return 0.9;
	if(h < 0.666666) return 0.1 + 4.8 * (0.666666 - h);
	return 0.1;
}

// Map [0, 1] to rgb using hues from [240, 0] - ie blue to red
float3 intensityToColour(float i) {
	// Algorithm rearranged from http://www.w3.org/TR/css3-color/#hsl-color
	// with s = 0.8, l = 0.5
	float h = 0.666666 - (i * 0.666666);
	return float3(h2rgb(h + 0.333333), h2rgb(h), h2rgb(h - 0.333333));
}

float Fresnel(float3 normalWS, float3 viewDirWS, float power){
    return pow((1.0 - saturate(dot(normalize(normalWS), normalize(viewDirWS)))), power);
}
#endif // URP_UTIL_INCLUDED