Shader "URP_Practise/PureC"
{
    Properties
    {
        [HideInInspector]_MainTex("MainTex",2D)="white"{}
        _Soildcolor("Color",Color) = (1,1,1,1)
        _VignetteTex("Vignette Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
        }

        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_TexelSize;

        CBUFFER_END
        
        float4 _Soildcolor;
        

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_VignetteTex);
        SAMPLER(sampler_VignetteTex);
        TEXTURE2D(_SourTex);
        SAMPLER(sampler_SourTex);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD;
        };
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma  vertex VERT
            #pragma fragment FRAG
            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord.xy = i.texcoord.xy;
                return o;
            }

            half4 FRAG(v2f i):SV_TARGET
            {
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy) * _Soildcolor;
                half4 vignetteTex = SAMPLE_TEXTURE2D(_VignetteTex, sampler_VignetteTex, i.texcoord.xy);
              //  color *= vignetteTex;
                color.a = _Soildcolor.a;
                return  color;
              
            }
            ENDHLSL

        }
        pass
        {
            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord.xy = i.texcoord.xy;
                return o;
            }

            half4 FRAG(v2f i) :SV_TARGET
            {
               
                real4 sour = SAMPLE_TEXTURE2D(_SourTex, sampler_SourTex, i.texcoord.xy);
                real4 soild = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord.xy);
                real4 color;

                color = sour * soild;

                return color;
            }
                ENDHLSL
        }
      
    }
}