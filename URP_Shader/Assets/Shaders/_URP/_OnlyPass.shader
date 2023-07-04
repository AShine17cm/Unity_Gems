Shader "_URP/OnlyPass"
{

    SubShader
    {
        LOD 100
        
        HLSLINCLUDE
        #ifndef URP_INPUT_INCLUDED
        #define URP_INPUT_INCLUDED
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
        #include "VertexLitInput.hlsl"
        half3 SampleSpecular(){
            return 0;
        }
        
        struct SurfaceData
        {
            half3 albedo;
            half alpha;
            half3 normalTS;
            half3 specular;
            half smoothness;
            half occlusion;
            half3 emission;
            half metallic;
        };
        
        inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
        {
            outSurfaceData.albedo =0;
            outSurfaceData.alpha =0;
            outSurfaceData.normalTS =0;
            outSurfaceData.specular =0;
            outSurfaceData.smoothness =0;
            outSurfaceData.occlusion =0;
            outSurfaceData.emission =0;
            outSurfaceData.metallic = 0;
        }
        
        half3 SampleEmissionMask(float2 uv, out float emissionMask){
            half3 emission = 0;
            emissionMask = 0;
            return emission;
        }
        
        #endif //URP_INPUT_INCLUDED
        ENDHLSL
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "TM_ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
             ZTest LEqual
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _SHADOW_OFFSET
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #include "DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "TM_DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            //#pragma shader_feature_local _ALPHATEST_ON
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "DepthOnlyPass.hlsl"
            ENDHLSL
        }
                
        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaSimple
            #pragma shader_feature_local _EMISSION
            //#pragma shader_feature _SPECGLOSSMAP
            
            #include "SimpleLitMetaPass.hlsl"

            ENDHLSL
        }
        
         // This pass it not used during regular rendering, only for lightmap baking.
         Pass
         {
             Name "LitMeta"
             Tags{ "LightMode" = "Meta" }

             Cull Off

             HLSLPROGRAM
             // Required to compile gles 2.0 with standard srp library
             #pragma prefer_hlslcc gles
             #pragma exclude_renderers d3d11_9x

             #pragma shader_feature_local _ALPHATEST_ON
             #pragma vertex UniversalVertexMeta
             #pragma fragment UniversalFragmentMeta

             #pragma shader_feature_local _EMISSION
             //  #pragma shader_feature _SPECGLOSSMAP
             #include "LitMetaPass.hlsl"

             ENDHLSL
         }
         
         // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "VertexLitMeta"
            Tags{ "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _EMISSION
            
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta
            
            #include "VertexLitMetaPass.hlsl"

            ENDHLSL
        }
        
        
        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "UnlitMeta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma shader_feature_local _ALPHATEST_ON
            
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            #include "UnlitMetaPass.hlsl"

            ENDHLSL
        }
    }
}
