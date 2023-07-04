Shader "Droplet"
{
    Properties
    {
       
        _MainTex("MainTex",2D)="white"{}
        _DropetNormals("Droplet Normals",2D)="white"{}
        _DropletCutout("DropletCutout",2D)="white"{}
        [Toggle]_EnableWetLens("Enable Wet Lens",Float)=1
        _Wetness("Wetness",Float)=0

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

       

        float4 _DropetNormals_ST;

        float4 _DropletCutout_ST;

     
        half _EnableWetLens;

        half _Wetness;
        
        CBUFFER_END


        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        TEXTURE2D(_DropetNormals);
        SAMPLER(sampler_DropetNormals);

        TEXTURE2D(_DropletCutout);
        SAMPLER(sampler_DropletCutout);


        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD0;
          
        };

        struct v2f_up
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD0;
           
        };

      
        v2f_up VERT(a2v i) 
        {
            v2f_up o;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            o.texcoord = i.texcoord;
          
            return o;
        }

        half4 FRAG(v2f_up i):SV_TARGET
        {
      
           float2 uv_DropletCutout=TRANSFORM_TEX(i.texcoord,_DropletCutout);
           float4 tex2DCutout=SAMPLE_TEXTURE2D(_DropletCutout,sampler_DropletCutout,uv_DropletCutout);
           float2 uv_DropletNormals=TRANSFORM_TEX(i.texcoord,_DropetNormals);
           float4 tex2DNormal=SAMPLE_TEXTURE2D(_DropetNormals,sampler_DropetNormals,uv_DropletNormals);
           float2 uv1=i.texcoord.xy * float2( 1,1 ) +( saturate( ( tex2DCutout.r + tex2DCutout.g + tex2DCutout.b ) ) *tex2DNormal.rga *_Wetness).xy;
           float2 uv2=i.texcoord.xy * float2( 1,1 ) +float2( 0,0 );
           float4 lerpResult142 = lerp( SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, uv1  ) , SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, uv2  ) , lerp(0.0,1.0,_EnableWetLens)); 

           return lerpResult142 ;
        }
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT

            #pragma fragment FRAG
            ENDHLSL
        }

    }

}