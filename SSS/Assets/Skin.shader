Shader "Unlit/Skin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SSSLUTTex("Skin Lut", 2D) = "white" {}
        _CurveFactor("Curve Factor",Float)=1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CurveFactor;

            float3 fwidth(float3 v) 
            {
                return abs(ddx(v)) + abs(ddy(v));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //float curve = saturate(_CurveFactor * (length(fwidth(worldNormal)) / length(fwidth(worldPos))));
                //fixed NDotL = dot(blurNormalDirection, lightDirection);
                //fixed4 sssColor = tex2D(_SSSLUTTex, float2(NDotL * 0.5 + 0.5, curve)) * _LightColor0;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
