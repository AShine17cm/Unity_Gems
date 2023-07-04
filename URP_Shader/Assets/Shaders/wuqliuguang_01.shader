// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:0,bsrc:0,bdst:0,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:True,fgod:False,fgor:False,fgmd:0,fgcr:0,fgcg:0,fgcb:0,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4795,x:32724,y:32693,varname:node_4795,prsc:2|emission-2393-OUT,alpha-9240-OUT,clip-9240-OUT;n:type:ShaderForge.SFN_Tex2d,id:6074,x:31988,y:32601,ptovrint:False,ptlb:MainTex,ptin:_MainTex,varname:_MainTex,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-9722-UVOUT;n:type:ShaderForge.SFN_Multiply,id:2393,x:32390,y:32758,varname:node_2393,prsc:2|A-6074-RGB,B-2053-RGB,C-797-RGB,D-9248-OUT;n:type:ShaderForge.SFN_VertexColor,id:2053,x:31826,y:32755,varname:node_2053,prsc:2;n:type:ShaderForge.SFN_Color,id:797,x:31826,y:32895,ptovrint:True,ptlb:Color,ptin:_TintColor,varname:_TintColor,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Vector1,id:9248,x:32032,y:32823,varname:node_9248,prsc:2,v1:2;n:type:ShaderForge.SFN_Panner,id:9722,x:31671,y:32604,varname:node_9722,prsc:2,spu:1,spv:1|UVIN-7015-UVOUT,DIST-3803-OUT;n:type:ShaderForge.SFN_Time,id:2382,x:31228,y:32711,varname:node_2382,prsc:2;n:type:ShaderForge.SFN_Tex2d,id:5442,x:32094,y:32987,ptovrint:False,ptlb:zhezhao_01,ptin:_zhezhao_01,varname:node_5442,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_TexCoord,id:7015,x:31341,y:32552,varname:node_7015,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Multiply,id:3803,x:31580,y:32755,varname:node_3803,prsc:2|A-2382-TSL,B-5552-OUT;n:type:ShaderForge.SFN_ValueProperty,id:5552,x:31294,y:32852,ptovrint:False,ptlb:speed,ptin:_speed,varname:node_5552,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_Multiply,id:9240,x:32446,y:32947,varname:node_9240,prsc:2|A-5442-A,B-797-A,C-2053-A;proporder:797-6074-5442-5552;pass:END;sub:END;*/

Shader "Shader Forge/wuqliuguang_01" {
    Properties {
        _TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _zhezhao_01 ("zhezhao_01", 2D) = "white" {}
        _speed ("speed", Float ) = 0
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
        CGINCLUDE
#pragma skip_variants LIGHTMAP_ON
            ENDCG
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Name "FORWARD"
            Tags {
                
            }
            Blend One One
            ZWrite Off
            
            CGPROGRAM
                        #pragma prefer_hlslcc gles
#pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float4 _TintColor;
            uniform sampler2D _zhezhao_01; uniform float4 _zhezhao_01_ST;
            uniform float _speed;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
                UNITY_FOG_COORDS(1)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                float4 _zhezhao_01_var = tex2D(_zhezhao_01,TRANSFORM_TEX(i.uv0, _zhezhao_01));
                float node_9240 = (_zhezhao_01_var.a*_TintColor.a*i.vertexColor.a);
                clip(node_9240 - 0.5);
////// Lighting:
////// Emissive:
                float4 node_2382 = _Time;
                float2 node_9722 = (i.uv0+(node_2382.r*_speed)*float2(1,1));
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(node_9722, _MainTex));
                float3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*2.0);
                float3 finalColor = emissive;
                fixed4 finalRGBA = fixed4(finalColor,node_9240);
                UNITY_APPLY_FOG_COLOR(i.fogCoord, finalRGBA, fixed4(0,0,0,1));
                return finalRGBA;
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
