Shader "_URP/VFX/Particles Alpha Blended"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
        [HDR] _BaseColor("Color", Color) =  (.5, .5, .5, .5)
        [Toggle(_SOFTPARTICLES_ON)] _EnableSoftParticle("Enable Soft Particle", Float) = 0
        [ShowIfEnabled(_SOFTPARTICLES_ON)] _InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 0.5
    }
    
    SubShader
    {
        Tags {  "Queue"="Transparent"  "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"  "PreviewType"="Plane"}
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB
        Cull Off Lighting Off ZWrite Off
		UsePass "_URP/VFX/Particles Additive/Particle"
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
