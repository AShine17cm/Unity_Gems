Shader "Stencil"
{
	Properties
	{
		[IntRange] _StencilID("Stencil ID", Range(0,255)) = 1
	
	}

		SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}

		Pass
		{

			ColorMask 0
			ZWrite Off
		  
			Stencil
			{
				Ref[_StencilID]
				Comp Always
				Pass Replace
				
			}
		}
	}
}