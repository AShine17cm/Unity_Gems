Shader "_URP/VFX/Water_Back"
{
	Properties
	{ 
		[NoScaleOffset][Header(Wave Options)]_NormalTexture("Normal Texture", 2D) = "bump" {}
		_NormalTiling("Normal Tiling", Range( 0.01 , 2)) = 0.792
		_NormalStrength("Normal Strength", Range( 0 , 2)) = 0.95
		_WaveSpeed("Wave Speed", Float) = 0.1
		_Refraction("Refraction", Range( 0 , 1)) = 0.1
		_DeepWaterColor("Deep Water Color", Color) = (0,0,0,0)
		[Header(Distance Options)]_MediumTilingDistance("Medium Tiling Distance", Float) = 100
		_FarTilingDistance("Far Tiling Distance", Float) = 1000
		_DistanceFade("Distance Fade", Float) = 0.5
		[HideInInspector]_RippleStrength("Ripple Strength", Range( 0 , 1)) = 0.5
		_PhysicalNormalStrength("Physical Normal Strength", Range( 0 , 1)) =0.202
	}
	 HLSLINCLUDE
	 #define FOG_LINEAR 1
	#pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
	#pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	 ENDHLSL
		SubShader
		{
		    Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0" "IsEmissive" = "true" }
		//	LOD 200
			Pass
			{
				
				Name "ForwardLit"
				Tags { "LightMode" = "UniversalForward" }
			
				Cull Front
				HLSLPROGRAM
				#pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0
			    #pragma multi_compile_fwdbase	
				 // GPU Instancing
				//#pragma multi_compile_instancing
                #pragma shader_feature _NORMALMAP
				#pragma shader_feature _ISRender_Off
				 //#pragma multi_compile__ _ISRender_Off
                 // Universal Pipeline keywords
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				
				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				 #include "WaterBack.hlsl"
				#pragma vertex vert	
				#pragma fragment frag
			 ENDHLSL
			 }
		}
		FallBack Off
}
