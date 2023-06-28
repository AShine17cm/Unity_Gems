Shader "Custom/Skin_BTDF"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        _LocalThickness("Local Thickness ( R )", 2D) = "white" {}
        _Distortion("Distortion Of Light",Range(0,1))=0.3
        _Power(" Power of Scaterring ",Range(0,10))=3       //皮肤的散射强度
        _Scale(" Scale of Light",Range(0,10))=2             //灯光的透射强度
        _Attenuation("Attenuation",Range(0,1))=0.5
        _Ambient("Indirect Translucency", Color) = (1,1,1,1)

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        //#pragma surface surf Standard fullforwardshadows
        #pragma surface surf StandardTranslucent fullforwardshadows
        #include "UnityPBSLighting.cginc"
        //#include "UnityGlobalIllumination.cginc"
        //#include "UnityCG.cginc"
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        //BTDF
        sampler2D _LocalThickness;
        float _Distortion, _Power, _Scale, _Attenuation;
        float4 _Ambient;
        float thickness;

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            thickness = tex2D(_LocalThickness, IN.uv_MainTex).r;
        }

        //与光照函数相互对应
        inline void LightingStandardTranslucent_GI(
            SurfaceOutputStandard s,
            UnityGIInput data,
            inout UnityGI gi)
        {
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
#else
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
#endif
        }
        //光照函数
        inline half4 LightingStandardTranslucent(SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
        {
            //原始  PBR
            fixed4 pbr = LightingStandard(s, viewDir, gi);
            //thickness = 1 - thickness;
            //透明
            float3 L = gi.light.dir;
            float3 V = viewDir;
            float3 N = s.Normal;

            float3 H = normalize(L + N * _Distortion);  //光线的扭曲
            float VdotH = pow(saturate(dot(V, -H)), _Power) * _Scale;   //散射程度, 灯光透射强度
            float3 I = _Attenuation * (VdotH + _Ambient) * thickness;   //直接透明，间接透明 都受到厚度影响

            pbr.rgb = pbr.rgb + gi.light.color * I;

            return pbr;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
