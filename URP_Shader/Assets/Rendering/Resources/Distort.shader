Shader "URP_Practise/Distort"
{
    Properties
    {
        //虽然从来没有对这个MainTex赋过值，但是猜测在Blit的时候就将source的RT作为MainTex传过来了
        //并且，我尝试了将其关键字修改之后整个Shader就失效了，应该是个小Trick，记住就好
        _MainTex("MainTex",2D)="white"{}
        _Distortion("Distortion",Range(0,0.1)) = 0.01
        _LerpDistort("LerpDistort",Range(0,1)) = 0.01
        _DistortionLens("DistortionLens", 2D) = "white" {}
        
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

        float4 _DistortionLens_ST;

      

        half _Distortion;

        half _LerpDistort;

        
        CBUFFER_END

        float _KawaseBlur;

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

       

        TEXTURE2D(_DistortionLens);
        SAMPLER(sampler_DistortionLens);

        struct a2v
        {
            float4 positionOS:POSITION;
            float2 texcoord:TEXCOORD0;
          
        };

        struct v2f_up
        {
            float4 positionCS:SV_POSITION;
            float2 texcoord:TEXCOORD0;
            float4 screenPos:TEXCOORD1;
        };

        //这是一种写法，规范来说其实应该把他放到下面的那个Pass里
        v2f_up VERT(a2v i) //水平方向的采样
        {
            v2f_up o;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            o.texcoord = i.texcoord;
            o.screenPos=ComputeScreenPos(o.positionCS);
            return o;
        }

        half4 FRAG(v2f_up i):SV_TARGET
        {
            half4 tex = half4(0,0,0,0);
            //_MainTex_TexelSize是当前屏幕分辨率的倒数
            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,-1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,-1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(-1,1)*_MainTex_TexelSize.xy*_KawaseBlur);

            tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord+float2(1,1)*_MainTex_TexelSize.xy*_KawaseBlur);


           float2 uv0_DistortionLens = i.texcoord.xy * _DistortionLens_ST.xy + _DistortionLens_ST.zw;
           float cos95 = cos( 5.0 * _Time.y );
		   float sin95 = sin( 5.0 * _Time.y );
           float2 rotator95 = mul( uv0_DistortionLens - float2( 0.5,0.5 ) , float2x2( cos95 , -sin95 , sin95 , cos95 )) + float2( 0.5,0.5 );
           float cos136 = cos( 1.5708 );
		   float sin136 = sin( 1.5708 );
		   float2 rotator136 = mul( uv0_DistortionLens - float2( 0.5,0.5 ) , float2x2( cos136 , -sin136 , sin136 , cos136 )) + float2( 0.5,0.5 );
           float cos139 = cos( 5.0 * _Time.y );
		   float sin139 = sin( 5.0 * _Time.y );
           float2 rotator139 = mul( rotator136 - float2( 0.5,0.5 ) , float2x2( cos139 , -sin139 , sin139 , cos139 )) + float2( 0.5,0.5 );
		   float temp_output_140_0 = ( SAMPLE_TEXTURE2D( _DistortionLens,sampler_DistortionLens, rotator95 ).r - SAMPLE_TEXTURE2D( _DistortionLens,sampler_DistortionLens, rotator139 ).r );
		   float2 appendResult132 = (float2(temp_output_140_0 , temp_output_140_0));
           float4 ase_screenPosNorm = i.screenPos / i.screenPos.w;
           ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
           float2 break116 = abs( (float2( -1,-1 ) + ((ase_screenPosNorm).xy - float2( 0,0 )) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 ))) );
          // float2 uv_DepthMask = i.texcoord.xy * _DepthMask_ST.xy + _DepthMask_ST.zw;
		  // float4 tex2DNode21 = SAMPLE_TEXTURE2D( _DepthMask, sampler_DepthMask,uv_DepthMask );
		 // float temp_output_41_0 = ( tex2DNode21.g + tex2DNode21.b );
           float4 lerpResult142 = lerp( SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, i.texcoord.xy * float2( 1,1 ) ) , SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, (i.texcoord.xy * float2( 1,1 ) + ( appendResult132 * ( 1.0 - pow( max( break116.x , break116.y ) , 3.0 ) ) * _Distortion ) ) ) , _LerpDistort); 

           // return tex * 0.25;
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