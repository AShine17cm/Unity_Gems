Shader "_URP/VFX/BillboardLensFlare"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _BaseMap("Texture", 2D) = "white" {}
        _BaseColorRGBIntensity("BaseColorRGBIntensity", Float) = 1
        
        //////////////////////////////////////////////////////////////////////////////////////////
        //custom settings
        //////////////////////////////////////////////////////////////////////////////////////////
        [Header(PreMultiply Alpha. Turn it ON only if your texture has correct alpha)]
        // (recommend _BaseMap's alpha = 'From Gray Scale')
        [Toggle]_UsePreMultiplyAlpha("UsePreMultiplyAlpha", Float) = 0

        [Header(Depth Occlusion)]
        _LightSourceViewSpaceRadius("LightSourceViewSpaceRadius", range(0,1)) = 0.05
        _DepthOcclusionTestZBias("DepthOcclusionTestZBias", range(-1,1)) = -0.001

        [Header(If camera too close Auto fadeout)]
        _StartFadeinDistanceWorldUnit("StartFadeinDistanceWorldUnit",Float) = 0.05
        _EndFadeinDistanceWorldUnit("EndFadeinDistanceWorldUnit", Float) = 0.5

        [Header(Optional Flicker animation)]
        [Toggle]_ShouldDoFlicker("ShouldDoFlicker", FLoat) = 1
        _FlickerAnimSpeed("FlickerAnimSpeed", Float) = 5
        _FlickResultIntensityLowestPoint("FlickResultIntensityLowestPoint", range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { 
            //lens flare is the artifact inside camera itself, so it should be drawn as late as possible 
            "RenderType" = "Overlay" "Queue" = "Overlay" 
            
            //we need object space vertex position, can't allow dynamic batching
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
             "RenderPipeline" = "UniversalPipeline" 
             "PreviewType " = "Plane" 
        }
        LOD 100
        
        //we will do multiple depth tests inside the vertex shader, so turn every Z related setting off
        ZWrite Off
        ZTest Off
        
        //Blend OneMinusDstColor One , aka Soft Additive (photoshop's screen blend)
        //will conflict with HDR, so we can't use it
        //Blend One One             //HDR friendly option(1), limited possibility
        Blend One OneMinusSrcAlpha  //HDR friendly option(2), which can produce all option(1)'s result also when alpha = 0
        
        // Include material cbuffer for all passes. 
        // The cbuffer has to be the same for all passes to make this shader SRP batcher compatible.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        SAMPLER(_CameraDepthTexture);

        CBUFFER_START(UnityPerMaterial)

        float4 _BaseMap_ST;
        half4 _BaseColor;
        half _BaseColorRGBIntensity;

        float _UsePreMultiplyAlpha;
        
        float _LightSourceViewSpaceRadius;
        float _DepthOcclusionTestZBias;

        float _StartFadeinDistanceWorldUnit;
        float _EndFadeinDistanceWorldUnit;

        float _FlickerAnimSpeed;
        float _FlickResultIntensityLowestPoint;
        float _ShouldDoFlicker;

        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Name "PassTest"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                half4 color             : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv               : TEXCOORD0;
                float4 color            : TEXCOORD1;
                float4 positionCS       : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            //you can edit to any number(e.g. 1~32), the lower the faster. Keeping this number a const can enable many compiler optimizations
            #define COUNT 8 

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.color = input.color * _BaseColor;
                output.color.rgb *= _BaseColorRGBIntensity;
                
                float3 quadPivotPosOS = 0;
                float3 quadPivotPosWS = TransformObjectToWorld(quadPivotPosOS);
                float3 quadPivotPosVS = TransformWorldToView(quadPivotPosWS);
                
                float2 scaleXY_WS = float2(
                    length(float3(GetObjectToWorldMatrix()[0].x, GetObjectToWorldMatrix()[1].x, GetObjectToWorldMatrix()[2].x)), // scale x axis
                    length(float3(GetObjectToWorldMatrix()[0].y, GetObjectToWorldMatrix()[1].y, GetObjectToWorldMatrix()[2].y)) // scale y axis
                );
                
                float3 posVS = quadPivotPosVS + float3(input.positionOS.xy * scaleXY_WS,0);//recontruct quad 4 points in view space
                
                output.positionCS = TransformWViewToHClip(posVS);
                
                //do smooth visibility test using brute force forloop (COUNT*2+1)^2 times inside a view space 2D grid area
                float visibilityTestPassedCount = 0;
                float linearEyeDepthOfFlarePivot = -quadPivotPosVS.z;//view space's forward is pointing to -Z, but we want +Z, so negate it
                float testLoopSingleAxisWidth = COUNT*2+1;
                float totalTestCount = testLoopSingleAxisWidth * testLoopSingleAxisWidth;
                float divider = 1.0 / totalTestCount;
                float maxSingleAxisOffset = _LightSourceViewSpaceRadius / testLoopSingleAxisWidth;
                
                //Test for n*n grid in view space, where quad pivot is grid's center.
                //For each iteration,
                //if that test point passed the scene depth occlusion test, we add 1 to visibilityTestPassedCount               
                for(int x = -COUNT; x<=COUNT; x++){
                    for(int y = -COUNT; y<=COUNT; y++){
                        float3 testPosVS = quadPivotPosVS;
                        testPosVS.xy += float2(x,y) * maxSingleAxisOffset;
                        float4 pivotPosCS = TransformWViewToHClip(testPosVS);
                        float4 pivotScreenPos = ComputeScreenPos(pivotPosCS);
                        float2 screenUV = pivotScreenPos.xy/pivotScreenPos.w;
                        
                        //if screenUV out of bound, treat it as occluded, because no correct depth texture data can be used to compare
                        if(screenUV.x > 1 || screenUV.x < 0 || screenUV.y > 1 || screenUV.y < 0)
                            continue; //exit means occluded
                            
                        //we don't have tex2D() in vertex shader, because rasterization is not done by GPU, so we use tex2Dlod() with mip0 instead
                        float sampledSceneDepth = tex2Dlod(_CameraDepthTexture,float4(screenUV,0,0)).x;//(uv.x,uv.y,0,mipLevel)
                        float linearEyeDepthFromSceneDepthTexture = LinearEyeDepth(sampledSceneDepth,_ZBufferParams);
                        float linearEyeDepthFromSelfALU = pivotPosCS.w; //clip space .w is view space z, = linear eye depth
                        //do the actual depth comparision test
                        //+1 means flare test point is visible in screen space
                        //+0 means flare test point blocked by other objects in screen space, not visible
                        visibilityTestPassedCount += linearEyeDepthFromSelfALU + _DepthOcclusionTestZBias < linearEyeDepthFromSceneDepthTexture ? 1 : 0; 
                    }
                }
                
                float visibilityResult01 = visibilityTestPassedCount * divider;//0~100% visiblility result 
                visibilityResult01 *= smoothstep(_StartFadeinDistanceWorldUnit,_EndFadeinDistanceWorldUnit,linearEyeDepthOfFlarePivot);
               if(_ShouldDoFlicker)
                {
                    float flickerMul = 0;
                    flickerMul += saturate(sin(_Time.y * _FlickerAnimSpeed * 1.0000)) * (1-_FlickResultIntensityLowestPoint) + _FlickResultIntensityLowestPoint;
                    flickerMul += saturate(sin(_Time.y * _FlickerAnimSpeed * 0.6437)) * (1-_FlickResultIntensityLowestPoint) + _FlickResultIntensityLowestPoint;   
                    visibilityResult01 *= saturate(flickerMul/2);
                }
                
                output.color.a *= visibilityResult01;
                output.color.rgb *=output.color.a;
                output.color.a = _UsePreMultiplyAlpha? output.color.a : 0;
                
                output.positionCS = visibilityResult01 < divider ? float4(999,999,999,1) : output.positionCS;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor * input.color;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
