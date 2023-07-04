Shader "_URP/Water_new"
{
	Properties
	{ 
		[Header(Gradient)]
		_ShallowColor("Shallow Color", Color) = (0,0.4867925,0.6792453,0)
		_DeepWaterColor("Deep Water Color", Color) = (0.2,0.2712264,0.8,0)
		_DepthRange("DepthRange",Range(0.1,10)) = 0.78
		[Header(Base Wave)]
		_WaveMap("Wave Map",2D) = "bump"{}
		_WaveAngle("WaveAngle",Range(0,90))=0
		_WaveXSpeed("Wave X Speed",Range(-0.1,0.1)) = 0.01
		_WaveYSpeed("Wave Y Speed",Range(-0.1,0.1)) = 0.01
		_Direction("Direction",Vector)=(1,1,1,1)
		
		[Header(Specular)]
		_Smoothness("Smoothness",Range(0.1,2)) = 1
		_SpecularColor("SpecularColor",Color) = (1,1,1,1)
		_FresnelPower("Fresnel Power", Range(.001, 128)) = 32
		 [Header(Reflect)]
		_Reflection("Reflection",Range(0,1)) = 1
		_ReflectColor("ReflectColor",Color) = (1,1,1,1)
		_Cubemap("Environment CubeMap",Cube) = "_Skybox"{}
		[Header(Refract)]
		_Distortion("Distortion",Range(0.1,10)) = 5
		[Header(Caustic)]
		_CausticTex("Caustic",2D)="white"{}
		_Caustic1_ST("Caustic1 ST",Vector)=(1,1,0,0)
		_Caustic2_ST("Caustic1 ST",Vector)=(1,1,0,0)
		_CausticRange("CausticRange", Range(0.1,10)) = 0.09
		_CausticSpeed("CausticSpeed",Vector) = (1,1,0,0)
		[Header(Foam)]
		_FoamTex("FoamTex",2D)="white"{}
		_FoamRange("FoamRange",Range(0.1,10))=0.16
		_FoamWaveDelta("FoamWaveDelta",Range(-50,50))=9.43
		_NoiseTex("Noise",2D)="white"{}
		_FoamSpeed("FoamSpeed",float)=-12.64
		_NoiseRange("NoiseRange",float)=6.43
		_WaterRange("WaterRange", Range(0.1,10)) = 0.21	//°×Ä­·¶Î§
		_WaveRange("WaveRange", Range(0.1,3)) = 0.21	
		_MaxDistance("MaxDistance",Range(0,1000))=10
		_MinDistance("MinDistance",Range(0,100))=10
	}
	    HLSLINCLUDE
		#define FOG_LINEAR 1
		#pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
		#pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		
	    ENDHLSL
		SubShader
		{
		    Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0"}
			LOD 300
		    //Pass
      //      {
      //      Name "ZOnly"
      //      Tags {"LightMode" = "PreForward"}
      //      ZWrite On
      //      ColorMask 0
      //      }
			Pass
			{
				
				Name "ForwardLit"
				Tags { "LightMode" = "UniversalForward" }
				Blend SrcAlpha OneMinusSrcAlpha
                ZWrite Off
			//	ZTest Equal
				//Cull Off
				HLSLPROGRAM
				#pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0
			    #pragma multi_compile_fwdbase	
				 // GPU Instancing
				//#pragma multi_compile_instancing
				 // -------------------------------------
                 // Universal Pipeline keywords
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				//#pragma multi_compile WATER_COMPLEX WATER_SIMPLE
				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				 #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
				 #include "ShaderLibrary/Util.hlsl"
				 #include "Water.hlsl"
				#pragma vertex vertH	
				#pragma fragment fragHigh 
			 ENDHLSL
			 }
		}
		SubShader
		{
		    Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0"}
			LOD 250
			//Pass
   //         {
   //         Name "ZOnly"
   //         Tags {"LightMode" = "PreForward"}
   //         ZWrite On
   //         ColorMask 0
   //         }
			Pass
			{
				
				Name "ForwardLit"
				Tags { "LightMode" = "UniversalForward" }
				Blend SrcAlpha OneMinusSrcAlpha
                ZWrite Off
				//ZTest Equal
				//Cull Off
				HLSLPROGRAM
				#pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0
			    #pragma multi_compile_fwdbase	
				 // GPU Instancing
				//#pragma multi_compile_instancing
				 // -------------------------------------
                 // Universal Pipeline keywords
				#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				//#pragma multi_compile WATER_COMPLEX WATER_SIMPLE
				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				 #include "ShaderLibrary/Util.hlsl"
				 #include "Water.hlsl"
				#pragma vertex vertH
				#pragma fragment fragMedium 
			 ENDHLSL
			 }
		}
		SubShader
		{
		    Tags{ "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0"}
			LOD 200
			//Pass
   //         {
   //         Name "ZOnly"
   //         Tags {"LightMode" = "PreForward"}
   //         ZWrite On
   //         ColorMask 0
   //         }
			Pass
			{
				
				Name "ForwardLit"
				Tags { "LightMode" = "UniversalForward" }
				Blend SrcAlpha OneMinusSrcAlpha
                ZWrite Off
				//ZTest Equal
				//Cull Off
				HLSLPROGRAM
				#pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0
			    #pragma multi_compile_fwdbase	
				 // GPU Instancing
				//#pragma multi_compile_instancing
				 // -------------------------------------
                 // Universal Pipeline keywords
				 #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
				 //#pragma multi_compile WATER_COMPLEX WATER_SIMPLE
				 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				 #include "ShaderLibrary/Util.hlsl"
				 #include "Water.hlsl"
				#pragma vertex vertL	
				#pragma fragment fragLow
			 ENDHLSL
			 }
		}		
		
		FallBack Off
}
