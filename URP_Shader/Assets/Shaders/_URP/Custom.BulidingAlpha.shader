Shader "_URP/Custom/BulidingAlpha"
{
	Properties
	{
		_MainTex("Texture Sample 0", 2D) = "white" {}
		_MainColor("MainColor", Color) = (1,1,1,1)
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 100

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#pragma target 2.0

        CBUFFER_START(UnityPerMaterial)
        half4 _MainColor;
        float4 _MainTex_ST;
        CBUFFER_END
        TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
		ENDHLSL
		
		Blend SrcAlpha OneMinusSrcAlpha
		//AlphaToMask On
		Cull Back
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		
		Pass
		{
			Name "Unlit"
			
			HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            //#pragma exclude_renderers d3d11_9x
            
			#pragma vertex vert
			#pragma fragment frag
			
			//#pragma multi_compile_instancing
			

			struct Attributes
			{
				float4 positionOS : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				
				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				
				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			
			Varyings vert ( Attributes input )
			{
				Varyings output = (Varyings)0;
				
				//UNITY_SETUP_INSTANCE_ID(input);
				//UNITY_TRANSFER_INSTANCE_ID(input, output);

				output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(positionWS);
				return output;
			}
			
			half4 frag (Varyings input ) : SV_Target
			{
				//UNITY_SETUP_INSTANCE_ID(input);
                half3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb ;
                return half4(texColor*_MainColor.rgb, _MainColor.a);
            }
			ENDHLSL
		}
	}
    FallBack "Hidden/Universal Render Pipeline/FallbackError"	
}
