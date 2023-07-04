#ifndef URP_IMAGE_ADJUST_INCLUDED
#define URP_IMAGE_ADJUST_INCLUDED

// boosts the contrast of an input by remapping the high end of the histogram to a lower value,
// and the low end of the histogram to a higher one.
// This is similar to applying a levels adjustment in Photoshop
void CheapContrast_float(float input, float contrast, out float output){
   output = saturate(lerp(0 - contrast, 1 + contrast, input));
}
#endif // URP_IMAGE_ADJUST_INCLUDED