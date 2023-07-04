Shader "Unlit/Tile"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color (A: Alpha)", Color) = (1,1,1,1)
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        [Enum(LEqual,4, Disabled,0)] _ZTest("Z Test", Float) = 4
        [Space]
        _Threshold("Threshold", Range(0, 1)) = 0.9        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Cull Off
            ZWrite Off
            ZTest [_ZTest]
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            
            #include "UnityCG.cginc"

            struct appdata
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color, _OutlineColor;
            fixed _Threshold;
            

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half alpha = tex2D(_MainTex, i.uv).a;
                clip(alpha - 0.5);
                half4 col = _Color;
                fixed w = fwidth(alpha) * 2.0;
                col.rgb = lerp(  _Color, _OutlineColor, smoothstep( -w, w, alpha - _Threshold));
                return col;
            }
            ENDCG
        }
    }
}
