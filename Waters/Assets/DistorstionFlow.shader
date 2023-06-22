Shader "Custom/DistorstionFlow"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [NoScaleOffset] _FlowMap("Flow (RG, A time-noise)",2D)="black"{}
        [NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
        [NoScaleOffset] _DerivHeightMap("Deriv (AG) Height (B)", 2D) = "black" {}

        _UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
        _VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
        _Tiling("Tiling", Float) = 1
        _Speed("Speed", Float) = 1
        _FlowStrength("Flow Strength", Float) = 1
        _HeightScale("Height Scale", Float) = 0.25
        _HeightScaleModulated("Height Scale, Modulated", Float) = 0.75

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        #include "Flow.cginc"
        sampler2D _MainTex,_NormalMap,_DerivHeightMap;
        float _UJump, _VJump,_Tiling,_Speed,_FlowStrength;   //flow-vector 相关参数
        float _HeightScale, _HeightScaleModulated;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        //差分图
        float3 UnpackDerivativeHeight(float4 textureData) 
        {
            float3 dh = textureData.agb;
            dh.xy = dh.xy * 2 - 1;
            return dh;
        }


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            
            float2 jump = float2(_UJump, _VJump);
            float3 uvwA = FlowUVW_Jump(IN.uv_MainTex,jump,_Tiling,_Speed,_FlowStrength, false);      //应用到UV
            float3 uvwB = FlowUVW_Jump(IN.uv_MainTex,jump,_Tiling,_Speed,_FlowStrength, true);
            //一般的法线
            //float3 normalA = UnpackNormal(tex2D(_NormalMap, uvwA.xy)) * uvwA.z;
            //float3 normalB = UnpackNormal(tex2D(_NormalMap, uvwB.xy)) * uvwB.z;
            //o.Normal = normalize(normalA + normalB);
            //差分图
            float2 flowVector = tex2D(_FlowMap, IN.uv_MainTex).rg * 2 - 1;		//梯度向量
            flowVector *= _FlowStrength;
            float finalHeightScale = length(flowVector) * _HeightScaleModulated + _HeightScale;

            float3 dhA =UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) * (uvwA.z* finalHeightScale);
            float3 dhB =UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) * (uvwB.z* finalHeightScale);
            o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));

            fixed4 texA = tex2D (_MainTex, uvwA.xy) * uvwA.z ;        //uvwA.z 是混合权重, 一个 ping-pong值
            fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z ;
            fixed4 c= (texA + texB) * _Color;
            o.Albedo = c.rgb;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
