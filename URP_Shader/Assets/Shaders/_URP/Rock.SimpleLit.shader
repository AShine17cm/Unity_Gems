Shader "_URP/Rock.SimpleLit"
{
    Properties
    {
        _Material_Quality("Material Quality", Float) = 0.0
        [ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
        
        [MainTexture] _BaseMap("Base Map (RGB) Occlusion (A)", 2D) = "gray" {}
        [NoScaleOffset] _NSMap("Normal Map (RGB), Smoothness(A)", 2D) = "gray" {}
        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
        _Smoothness("Smoothness", Float) = 0.5
        
        _EnableTriplanar("__enableTriplanar", Float) = 0.0
        _TextureSize("Texture Size", Vector) = (1, 1, 1, 1)
        
        _EnableMoss("Moss", Float) = 0.0
        _MossMap("Moss Color (RGB)", 2D) = "white" {}
        // _MossNMap("Moss Normal Map (RGB)", 2D) = "white" {}
        _MossScale("Moss Scale", Float) = 4.0
        _MossSmoothness("Moss Smoothness", Float) = 0.8
        
        _HeightBlend("Moss Height Blend", Float) = 1.0
        _BlendDistance("Moss Blend Distance", Float) = 1.0
        _BlendAngle("Moss Angle", Float) = 60.0
        
        _EnableIntersection("Intersection", Float) = 0.0
        _ValueRemap("Value Remap", Vector) = (0, 0.5, 0, 1)
        _EnableVertexOffset("Vertex Offset", Float) = 0.0
        _VertexOffset("Offset Amount", Vector) = (8, 8, 0, 1)
        _EnableShadowOffset("_EnableShadowOffset", Float) = 0.0
        _ShadowOffset("_ShadowOffset", Vector) = (-4.5, 1, 0, 0)
        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
        
        _DebugToggle("Debug", Float) = 0.0
        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _Shininess("Smoothness", Float) = 0.0
    }
    
    HLSLINCLUDE
    #define _ENV 1
    #define FOG_LINEAR 1
    #define _SPECULAR_SETUP 1
    #define _NORMALMAP 1
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX

    #include "Rock.SimpleLit.Input.hlsl"
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 250

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            ZTest LEqual
            
            Cull Back
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #define _NEED_POS_WS 1
            
            // -------------------------------------
            // Material Keywords
            
            #pragma shader_feature_local _DEBUG
            #pragma shader_feature _TRIPLANAR
            
            #pragma shader_feature _VCOLOR
            
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _SHADOW_OFFSET
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitVert
            #pragma fragment LitFrag

            #include "Rock.SimpleLitPass.hlsl"
            
            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/TM_DepthOnly"
        UsePass "_URP/OnlyPass/Meta"
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            ZTest LEqual
            
            Cull Back
            
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            // -------------------------------------
            // Material Keywords
            
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
             #pragma shader_feature_local _SHADOW_OFFSET
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitVert
            #pragma fragment LitFrag
     

            #include "VertexLitPass.hlsl"

            ENDHLSL
        }
        
        UsePass "_URP/OnlyPass/TM_ShadowCaster"
        UsePass "_URP/OnlyPass/TM_DepthOnly"
        UsePass "_URP/OnlyPass/VertexLitMeta"
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "URP.Editor.RockShaderGUI"
}
