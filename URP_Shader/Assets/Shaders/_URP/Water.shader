Shader "_URP/VFX/Water"
{
    Properties
    {
        _BumpMap("Normal Map", 2D) = "bump" {}
        _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
        _Smoothness("Smoothness", Float) = 0.5
        [Header(Ripples)]
        _ScaleA("Scale A", Range(.001, 10)) = 0.5
        _ScaleB("Scale B", Range(.001, 10)) = 0.1
        _Speed("Speed A xy, Speed B zw", Vector) = (0.5, 0.1, 0.25, -0.1)
        [Header(Depth)]
        _ColorShallow("Color Shallow", Color) = (.2, .7, .8, 1)
        _ColorDeep("Color Deep", Color) = (.2, .2, .8, 1)
        _MaxDepth("Max Depth", Range(.001, 10)) = 0.2
        _DepthPower("Depth Power", Range(.001, 10)) = 0.2
        _FresnelPower("Fresnel Power", Range(.001, 128)) = 32
        _FresnelColor("Fresnel Color (RGB)", Color) = (1, 1, 1, 1)
        _FoamColor("Foam Color (RGB), Contrast (A)", Color) = (1, 1, 1, 1)
    }
    
    HLSLINCLUDE
    #define FOG_LINEAR 1
    #pragma skip_variants _SHADOWS_SOFT DIRLIGHTMAP_COMBINED _MIXED_LIGHTING_SUBTRACTIVE
    #pragma skip_variants LIGHTMAP_ON _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _ADDITIONAL_LIGHTS_VERTEX
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    CBUFFER_START(UnityPerMaterial)
        half4 _SpecColor;
        half4 _ColorShallow;
        half4 _ColorDeep;
        half _MaxDepth;
        half _DepthPower;
        //half _FoamContrast;
        half _FresnelPower;
        half4 _FresnelColor;
        half4 _FoamColor;
        half _ScaleA;
        half _ScaleB;
        half _Smoothness;
        half4 _Speed;
        CBUFFER_END
        
        TEXTURE2D(_BumpMap);          SAMPLER(sampler_BumpMap);
       // TEXTURE2D(_SelfDepthTexture2); SAMPLER(sampler_SelfDepthTexture2);
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0"}
        LOD 250
    
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
		    Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            //Cull Off
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            

            // -------------------------------------
            // Material Keywords

            
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
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "ShaderLibrary/Coordinates.hlsl"
            #include "ShaderLibrary/Math.hlsl"
            #include "ShaderLibrary/Util.hlsl"
            #include "ShaderLibrary/Mask.hlsl"
            #include "ShaderLibrary/ImageAdjustment.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            

            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;
                float4 tangentOS        : TANGENT;
                float2 texcoord         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float3 positionWS               : TEXCOORD2;
                float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
                float4 VertexSHFogCoord         : TEXCOORD6;
                float4 screenPos                : TEXCOORD7;
                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
                
                output.uv = input.texcoord;
                output.VertexSHFogCoord.a = ComputeFogFactor(vertexInput.positionCS.z);
                OUTPUT_SH(output.normalWS.xyz, output.VertexSHFogCoord.rgb);
                
                output.screenPos = ComputeScreenPos(output.positionCS);
                return output;
            }
            
            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
            
                inputData.positionWS = input.positionWS;
            
                half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                inputData.normalWS = TransformTangentToWorld(normalTS,
                    half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
            
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                viewDirWS = SafeNormalize(viewDirWS);
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                inputData.fogCoord = input.VertexSHFogCoord.a;
                inputData.bakedGI = SampleSHPixel(input.VertexSHFogCoord.rgb, inputData.normalWS);
            }
            
            half2 DistortionUVs(half depth, float3 normalWS)
            {
                half3 viewNormal = mul((float3x3)GetWorldToHClipMatrix(), -normalWS).xyz;
                return viewNormal.xz * saturate((depth) * 0.005);
            }
            float DecodeFloatRGBA(float4 enc)
            {
	            float4 kDecodeDot = float4(1.0, 1 / 255.0, 1 / 65025.0, 1 / 160581375.0);
	            return dot(enc, kDecodeDot);
            }
            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                half2 uv = input.uv;
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.xy, uv);
                uv *= _ScaleA;
                half3 normalTS_A = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.zw, uv);
                uv *= _ScaleB;
                half3 normalTS_B = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.xy + _Speed.zw, uv);
                uv *= _ScaleB * _ScaleA * _ScaleB;
                half3 normalTS_C = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                half3 normalTS;
                DeriveNormalZ_float(normalTS_A.rg + normalTS_B.rg + normalTS_C.rg, 1, normalTS);
                
                half2 screenUV = input.screenPos.xy/input.screenPos.w;
               // half screenDepth = SampleSceneDepth(screenUV);
             //   half screenDepth=DecodeFloatRGBA(SAMPLE_TEXTURE2D(_SelfDepthTexture2, sampler_SelfDepthTexture2, screenUV));

              //  half depth =saturate(pow(abs(LinearEyeDepth(screenDepth, _ZBufferParams) - input.screenPos.w), _DepthPower));
              //  half adjustedDepth = saturate(remap(depth, 0, _MaxDepth, 0, 1));
                
                InputData inputData;
                InitializeInputData(input, normalTS, inputData);
                
                Light mainLight = GetMainLight(inputData.shadowCoord);
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                
                half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, inputData.normalWS);

                half3 H = normalize(mainLight.direction + inputData.viewDirectionWS);
                half3 specularColor = attenuatedLightColor * _SpecColor.rgb * pow(saturate(dot(inputData.normalWS, H)), _Smoothness);
                half foamEdge;
              //  CheapContrast_float(1 - depth, _FoamColor.a * 4, foamEdge);
                half fresnel = Fresnel (inputData.normalWS, inputData.viewDirectionWS, _FresnelPower) /** (1 - foamEdge)*/ ;
               // half4 depthColor = lerp(_ColorShallow, _ColorDeep, adjustedDepth);
                half4 depthColor = lerp(_ColorShallow, _ColorDeep, 0.5);
                half3 color = saturate(specularColor + diffuseColor * depthColor.rgb + fresnel * _FresnelColor.rgb);
              //  color = lerp(color, _FoamColor.rgb , foamEdge);
                color = MixFog(color, input.VertexSHFogCoord.a);
                half alpha = saturate( depthColor.a + fresnel);

                return half4(color, alpha);
            }
            ENDHLSL
        }
        

        
    }
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue"="Transparent+0"}
        LOD 200
    
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
		    Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
           // Cull Off
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords

            
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
            // #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ FOG_LINEAR
            
            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing
            

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
            #include "ShaderLibrary/Coordinates.hlsl"
            #include "ShaderLibrary/Math.hlsl"
            #include "ShaderLibrary/Util.hlsl"
            #include "ShaderLibrary/Mask.hlsl"
            #include "ShaderLibrary/ImageAdjustment.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;
                float4 tangentOS        : TANGENT;
                float2 texcoord         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv                       : TEXCOORD0;
                float3 positionWS               : TEXCOORD2;
                float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
                float4 VertexSHFogCoord         : TEXCOORD6;
                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
                
                output.uv = input.texcoord;
                output.VertexSHFogCoord.a = ComputeFogFactor(vertexInput.positionCS.z);
                OUTPUT_SH(output.normalWS.xyz, output.VertexSHFogCoord.rgb);
                
                return output;
            }
            
            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
            
                inputData.positionWS = input.positionWS;
            
                half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
                inputData.normalWS = TransformTangentToWorld(normalTS,
                    half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
            
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                viewDirWS = SafeNormalize(viewDirWS);
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                inputData.fogCoord = input.VertexSHFogCoord.a;
                inputData.bakedGI = SampleSHPixel(input.VertexSHFogCoord.rgb, inputData.normalWS);
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                half2 uv = input.uv;
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.xy, uv);
                uv *= _ScaleA;
                half3 normalTS_A = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.zw, uv);
                uv *= _ScaleB;
                half3 normalTS_B = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                Panner_float(input.positionWS.xz, _Time.y, _Speed.xy + _Speed.zw, uv);
                uv *= _ScaleB * _ScaleA * _ScaleB;
                half3 normalTS_C = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv));
                
                half3 normalTS;
                DeriveNormalZ_float(normalTS_A.rg + normalTS_B.rg + normalTS_C.rg, 1, normalTS);
                
                InputData inputData;
                InitializeInputData(input, normalTS, inputData);
                
                Light mainLight = GetMainLight(inputData.shadowCoord);
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                
                half3 diffuseColor = inputData.bakedGI + LightingLambert(attenuatedLightColor, mainLight.direction, inputData.normalWS);

                half3 H = normalize(mainLight.direction + inputData.viewDirectionWS);
                half3 specularColor = attenuatedLightColor * _SpecColor.rgb * pow(saturate(dot(inputData.normalWS, H)), _Smoothness);
                half fresnel = Fresnel (inputData.normalWS, inputData.viewDirectionWS, _FresnelPower) ;
                
                half3 color = saturate(specularColor + diffuseColor * _ColorShallow.rgb + fresnel * _FresnelColor.rgb);
                color = MixFog(color, input.VertexSHFogCoord.a);
                half alpha = saturate(fresnel + _ColorShallow.a);
                
                return half4(color, alpha);
            }
            ENDHLSL
        }
        

        
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
