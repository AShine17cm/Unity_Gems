Shader "Mg/Plant/Fruit"
{
	Properties
	{
		_BaseMap("Texture", 2D) = "white" {}
		tintA("Green",Color) = (0,1,0,1)
		amt("Amount of curve",Range(0,1))=0
		wrap("wrap of light",Float)=1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }
		LOD 300

		Pass
		{
			Tags{ "LightMode" = "UniversalForward" }
			//Cull Off
			HLSLPROGRAM
			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile_instancing
			#pragma vertex vert
			#pragma fragment frag
			#include "FruitPass.hlsl"
			ENDHLSL
		}
		Pass
		{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
			ZWrite On
			ZTest LEqual
			Cull Off
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0
			#pragma multi_compile_instancing

			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment
			#include "ShadowCasterPass.hlsl"
			ENDHLSL
		}
		//UsePass "Mg/MgComm/XSOLIDSHADOW"
		//UsePass "_URP/OnlyPass/DepthOnly"
		//UsePass "_URP/OnlyPass/VertexLitMeta"
	}
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
