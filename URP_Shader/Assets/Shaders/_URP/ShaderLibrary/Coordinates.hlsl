#ifndef URP_COORDINATES_INCLUDED
#define URP_COORDINATES_INCLUDED

// The ability to add motion to your Materials is a must, especially when you try to recreate effects
// such as fire, water, or smoke. A very cheap and effective way.
// Allows you to move the UV coordinates of your texture in either the U or V direciton or in combination of both
void Panner_float(float2 uv, float time, float2 speed, out float2 output){
    #if SHADERGRAPH_PREVIEW
        output = 0.5;
    #else
        output = time * speed + uv;
   #endif
}
#endif // URP_COORDINATES_INCLUDED