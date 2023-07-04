Shader "_URP/VFX_Blend"
{
    Properties
    {
		_MaterialMode("ShaderMode", Float) = 0
		[HideInInspector] _Cull("__cull", Float) = 2.0
        //power的系数
		_Extrusion("Extrusion", Float) = 1
		[HDR]_BaseColor("Color", Color) = (1,1,1,1)
		_BaseMap("BaseMap", 2D) = "white" {}
		_Main_U_Offset("Main_U_Offset", Float) = 0
		_Main_V_Offset("Main_V_Offset", Float) = 0
		_MainUVSpeedAndRota("Main uv Speed and Rota",Vector)=(0,0,0,0)
		_MaskMap("Mask", 2D) = "white" {}
		_MaskUVSpeedAndRota("Mask uv Speed & Rota & MaskIntensity",Vector)=(0,0,0,1.76)
		_PannerTex("PannerTex", 2D) = "white" {}
		_PannerUVSpeedAndRota("Panner uv Speed & Rota & PannerIntensity",Vector)=(0,0,0,0)
		_DissloveTex("DissloveTex", 2D) = "white" {}
		_DissloveUVSpeedAndRota("Disslove uv Speed & Rota & DissloveIntensity",Vector)=(0,0,0,0.02629435)
		_Hardness("Hardness", Range( 0 , 1)) = 1
		_Edgewidth("Edgewidth", Range( 0 , 1)) = 0
		[HDR]_EdgeColor("EdgeColor", Color) = (1,0,0,1)
		_Fresnel("Fresnel", Float) = 0
		[HDR]_FresnelColor("FresnelColor", Color) = (1,0,0,1)
		_FresnelWidth("FresnelWidth", Float) = 1
		_FresnelIntensity("FresnelIntensity", Float) = 1
		[Enum(Particle,0,Model,1)]_Mode("Mode", Float) = 0
	    [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
		[HideInInspector] _Blend("__blend", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
    }

	
    SubShader
    {
      Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"  "Queue"="Transparent" }
	  LOD 200
	 
	  Pass
	  {
		    Name "VFX"
			Tags { "LightMode"="UniversalForward" }
			Blend[_SrcBlend][_DstBlend], One OneMinusSrcAlpha
		  //Blend One One , One OneMinusSrcAlpha
			ZWrite Off
			Cull[_Cull]
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGB
			HLSLPROGRAM
			#pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
			#pragma shader_feature_local _ADDOrBLEND
			#pragma shader_feature_local _FresnelBlend_On
			#pragma shader_feature _RECEIVE_SHADOWS_OFF
			#pragma multi_compile_instancing

			#pragma vertex Vert
			#pragma fragment Frag

		    #include "VFXInput.hlsl"
			#include "VFXForwardPass2.hlsl"
			ENDHLSL
	  }
	}
	
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.VFXShaderGUI"
}
