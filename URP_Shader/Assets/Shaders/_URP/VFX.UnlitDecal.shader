Shader "_URP/VFX/UnlitDecal"
{
    Properties
    {
        [Header(Basic)]
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        
        [Header(Blending)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("_SrcBlend (SrcAlpha)", Float) = 5 //5 = SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("_DstBlend (OneMinusSrcAlpha)", Float) = 10 //10 = OneMinusSrcAlpha
        
        [Header(Alpha remap(extra alpha control))]
        // _____alpha will first mul x, then add y    (zw unused)
        _AlphaRemap("_AlphaRemap (1,0,0,0) (zw unused)", vector) = (1,0,0,0)

        [Header(Prevent Side Stretching)]
        //(Compare projection direction with scene normal and Discard if needed)
        [Toggle(_ProjectionAngleDiscardEnable)] _ProjectionAngleDiscardEnable("_ProjectionAngleDiscardEnable (off)", float) = 0
        [ShowIfNotZero(_ProjectionAngleDiscardEnable)]_ProjectionAngleDiscardThreshold("_ProjectionAngleDiscardThreshold (0)", range(-1,1)) = 0
        
        [Header(Mul alpha to rgb)]
        [Toggle]_MulAlphaToRGB("_MulAlphaToRGB (default = off)", Float) = 0

        [Header(Ignore texture wrap mode setting)]
        [Toggle(_FracUVEnable)] _FracUVEnable("_FracUVEnable (default = off)", Float) = 0
        
        [Header(Stencil Masking)]
        // _____Set to NotEqual if you want to mask by specific _StencilRef value, else set to Disable
        _StencilRef("_StencilRef", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp (Disable)", Float) = 0 //0 = disable

        [Header(ZTest)]
        //https://docs.unity3d.com/ScriptReference/Rendering.CompareFunction.html
        //default need to be Disable, 
        // because we need to make sure decal render correctly even if camera goes into decal cube volume, 
        // although disable ZTest by default will prevent EarlyZ (bad for GPU performance)
        //  _____to improve GPU performance, Set to LessEqual if camera never goes into cube volume, else set to Disable
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("_ZTest (Disable)", Float) = 0 //0 = disable

        [Header(Cull)]
        // default need to be Front, because we need to make sure decal render correctly even if camera goes into decal cube
        // Set to Back if camera never goes into cube volume, else set to Front
        //  _____to improve GPU performance, 
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("_Cull (Front)", Float) = 1 //1 = Front

        [Header(Unity Fog)]
        [Toggle(_UnityFogEnable)] _UnityFogEnable("_UnityFogEnable (on)", Float) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType" = "Overlay" "Queue" = "Transparent-499" 
            "RenderPipeline" = "UniversalPipeline" 
            "PreviewType " = "Plane" 
        }
        LOD 100
        
        Pass
        {
            Stencil {
                Ref[_StencilRef]
                Comp[_StencilComp]
            }
            Cull[_Cull]
            ZTest[_ZTest]

            ZWrite off
            Blend[_SrcBlend][_DstBlend]
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            // make fog work
            #pragma multi_compile _ FOG_LINEAR

            //due to using ddx() & ddy()
            #pragma target 3.0

            #pragma shader_feature_local _ProjectionAngleDiscardEnable
            #pragma shader_feature_local _UnityFogEnable
            #pragma shader_feature_local _FracUVEnable
            
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half2 _AlphaRemap;
                half _ProjectionAngleDiscardThreshold;
                half _MulAlphaToRGB;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS                           : SV_POSITION;
                float4 screenUV                             : TEXCOORD0;
                float4 viewRayOS                            : TEXCOORD1;
                float4 cameraPosOSAndFogFactor              : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                float3 posWS = TransformObjectToWorld(input.positionOS.rgb);
                float3 posVS = TransformWorldToView(posWS);
                output.positionCS = TransformWViewToHClip(posVS);
                
                #if _UnityFogEnable
                    output.cameraPosOSAndFogFactor.a = ComputeFogFactor(output.positionCS.z);
                #else
                    output.cameraPosOSAndFogFactor.a = 0;
                #endif
                
                output.screenUV = ComputeScreenPos(output.positionCS);
                
                float3 viewRay = TransformWorldToView(TransformObjectToWorld(input.positionOS.xyz));
                output.viewRayOS.w = viewRay.z;//pass the division value to varying o.viewRayOS.w
                viewRay *= -1; //unity's camera space is right hand coord(negativeZ pointing into screen), we want positive z ray in fragment shader, so negate it
                
                float4x4 ViewToObjectMatrix = mul(unity_WorldToObject, UNITY_MATRIX_I_V);

                //transform everything to object space(decal space) in vertex shader first, so we can skip all matrix mul() in fragment shader
                output.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, viewRay);
                output.cameraPosOSAndFogFactor.xyz = mul(ViewToObjectMatrix, float4(0,0,0,1)).xyz;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                input.viewRayOS/= input.viewRayOS.w;
                
                float screenCamearSpaceDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, input.screenUV.xy/input.screenUV.w).r, _ZBufferParams);
                // scene depth in any space = rayStartPos + rayDir * rayLength 
                // here all data in ObjectSpace(OS) or DecalSpace  
                float3 decalSpaceScenePos =  input.cameraPosOSAndFogFactor.xyz + input.viewRayOS.xyz * screenCamearSpaceDepth;
                
                // convert unity cube's [-0.5, 0.5] vertex pos range to [0, 1] uv. Only works if you use unity cube in mesh filter!
                float2 decalSpaceUV = decalSpaceScenePos.xy + 0.5;
                
                // discard logic
                float mask = (abs(decalSpaceScenePos.x) < 0.5? 1.0 : 0.0)
                            * (abs(decalSpaceScenePos.y) < 0.5? 1.0 : 0.0) 
                            * (abs(decalSpaceScenePos.z) < 0.5? 1.0 : 0.0);
                
                #if _ProjectionAngleDiscardEnable
                    // also discard "scene normal not facing decal projector direction" pixels
                    // reconstruct scene hard normal using scene pos ddx & ddy
                    float3 decalSpaceHardNormal = normalize(cross(ddx(decalSpaceScenePos), ddy(decalSpaceScenePos)));
                    // compare scene hard normal with decal projector's dir, 
                    // decalSpaceHardNormal.z equals dot(decalForwardDir,sceneHardNormalDir)
                    mask *= decalSpaceHardNormal.z > _ProjectionAngleDiscardThreshold? 1.0 :0.0;
                #endif
                
                    // if ZWrite is off, clip() is fast enough on mobile, 
                    // because it won't write the DepthBuffer, so no pipeline stall(confirmed by ARM staff).
                    clip(mask - 0.5);
                    // sample the decal texture
                    float2 uv = decalSpaceUV.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
                    
                #if _FracUVEnable
                    uv = frac(uv);
                #endif
                
                    half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
                    col *=_BaseColor;
                    col.a = saturate(col.a * _AlphaRemap.x + _AlphaRemap.y);
                    col.rgb *= lerp(1, col.a, _MulAlphaToRGB);
                #if _UnityFogEnable
                    col.rgb = MixFog(col.rgb, input.cameraPosOSAndFogFactor.a);
                #endif
                    
                    
                    return col;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
