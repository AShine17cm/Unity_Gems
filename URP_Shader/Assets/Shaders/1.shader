// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:0,bdst:0,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:True,fgod:False,fgor:False,fgmd:0,fgcr:0,fgcg:0,fgcb:0,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4795,x:33462,y:32778,varname:node_4795,prsc:2|emission-1508-OUT;n:type:ShaderForge.SFN_Multiply,id:9068,x:32383,y:32910,varname:node_9068,prsc:2|A-8303-RGB,B-8117-OUT;n:type:ShaderForge.SFN_Vector1,id:8117,x:32246,y:33106,varname:node_8117,prsc:2,v1:1;n:type:ShaderForge.SFN_Color,id:8303,x:31898,y:32884,ptovrint:False,ptlb:node_8303,ptin:_node_8303,varname:node_8303,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Fresnel,id:4549,x:32207,y:32736,varname:node_4549,prsc:2|EXP-9845-OUT;n:type:ShaderForge.SFN_Add,id:8280,x:32572,y:32792,varname:node_8280,prsc:2|A-1012-OUT,B-9068-OUT;n:type:ShaderForge.SFN_Vector1,id:9845,x:32035,y:32770,varname:node_9845,prsc:2,v1:5;n:type:ShaderForge.SFN_Multiply,id:6039,x:32366,y:32644,varname:node_6039,prsc:2|A-2450-OUT,B-4549-OUT;n:type:ShaderForge.SFN_Vector1,id:2464,x:32148,y:32884,varname:node_2464,prsc:2,v1:2;n:type:ShaderForge.SFN_Multiply,id:1012,x:32398,y:32778,varname:node_1012,prsc:2|A-6039-OUT,B-2464-OUT;n:type:ShaderForge.SFN_Multiply,id:5361,x:32764,y:32858,varname:node_5361,prsc:2|A-8280-OUT,B-3306-OUT;n:type:ShaderForge.SFN_Slider,id:3306,x:32461,y:33127,ptovrint:False,ptlb:node_3306,ptin:_node_3306,varname:node_3306,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.323261,max:2;n:type:ShaderForge.SFN_Multiply,id:2450,x:32169,y:32549,varname:node_2450,prsc:2|A-3832-OUT,B-8303-RGB;n:type:ShaderForge.SFN_Vector1,id:3832,x:31930,y:32533,varname:node_3832,prsc:2,v1:15;n:type:ShaderForge.SFN_Multiply,id:7855,x:32869,y:32600,varname:node_7855,prsc:2|A-8655-OUT,B-5361-OUT;n:type:ShaderForge.SFN_Vector1,id:8655,x:32625,y:32529,varname:node_8655,prsc:2,v1:0.25;n:type:ShaderForge.SFN_Vector1,id:7494,x:31329,y:33698,varname:node_7494,prsc:2,v1:2;n:type:ShaderForge.SFN_Panner,id:8212,x:31720,y:33364,varname:node_8212,prsc:2,spu:0,spv:0|UVIN-6936-OUT;n:type:ShaderForge.SFN_TexCoord,id:8707,x:31522,y:33552,varname:node_8707,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Multiply,id:7890,x:32203,y:33728,varname:node_7890,prsc:2|A-4862-RGB,B-4141-RGB;n:type:ShaderForge.SFN_Color,id:4141,x:32041,y:33805,ptovrint:False,ptlb:node_5059,ptin:_node_5059,varname:node_5059,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Tex2d,id:4862,x:31922,y:33327,ptovrint:False,ptlb:node_1605,ptin:_node_1605,varname:node_1605,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-8212-UVOUT;n:type:ShaderForge.SFN_Tex2d,id:6582,x:31313,y:33779,ptovrint:False,ptlb:node_4307,ptin:_node_4307,varname:node_4307,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-9194-UVOUT;n:type:ShaderForge.SFN_Panner,id:9194,x:31046,y:33784,varname:node_9194,prsc:2,spu:-0.02,spv:-0.1|UVIN-5064-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:5064,x:30782,y:33816,varname:node_5064,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Add,id:6936,x:31593,y:33744,varname:node_6936,prsc:2|A-8707-UVOUT,B-2159-OUT;n:type:ShaderForge.SFN_Multiply,id:2159,x:31557,y:34028,varname:node_2159,prsc:2|A-7684-OUT,B-6582-R;n:type:ShaderForge.SFN_Vector1,id:9032,x:31313,y:34062,varname:node_9032,prsc:2,v1:0.05;n:type:ShaderForge.SFN_Tex2d,id:9469,x:31177,y:33987,ptovrint:False,ptlb:node_7917,ptin:_node_7917,varname:node_7917,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-4334-UVOUT;n:type:ShaderForge.SFN_Add,id:7684,x:31362,y:33905,varname:node_7684,prsc:2|A-6582-R,B-9469-R;n:type:ShaderForge.SFN_Panner,id:4334,x:30980,y:33932,varname:node_4334,prsc:2,spu:0.15,spv:0.05|UVIN-5064-UVOUT;n:type:ShaderForge.SFN_Panner,id:8440,x:31954,y:33626,varname:node_8440,prsc:2,spu:-0.2,spv:-0.85|UVIN-6894-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:6894,x:31756,y:33692,varname:node_6894,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Add,id:8378,x:32958,y:33210,varname:node_8378,prsc:2|A-7855-OUT,B-7890-OUT;n:type:ShaderForge.SFN_Multiply,id:1508,x:33166,y:33103,varname:node_1508,prsc:2|A-3306-OUT,B-8378-OUT;proporder:8303-3306-4141-4862-6582-9469;pass:END;sub:END;*/

Shader "Shader Forge/1" {
    Properties {
        _node_8303 ("node_8303", Color) = (0.5,0.5,0.5,1)
        _node_3306 ("node_3306", Range(0, 2)) = 0.323261
        _node_5059 ("node_5059", Color) = (0.5,0.5,0.5,1)
        _node_1605 ("node_1605", 2D) = "white" {}
        _node_4307 ("node_4307", 2D) = "white" {}
        _node_7917 ("node_7917", 2D) = "white" {}
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
            Cull Off
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
            uniform float4 _node_8303;
            uniform float _node_3306;
            uniform float4 _node_5059;
            uniform sampler2D _node_1605; uniform float4 _node_1605_ST;
            uniform sampler2D _node_4307; uniform float4 _node_4307_ST;
            uniform sampler2D _node_7917; uniform float4 _node_7917_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                UNITY_FOG_COORDS(3)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                i.normalDir *= faceSign;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
////// Lighting:
////// Emissive:
                float4 node_3495 = _Time;
                float2 node_9194 = (i.uv0+node_3495.g*float2(-0.02,-0.1));
                float4 _node_4307_var = tex2D(_node_4307,TRANSFORM_TEX(node_9194, _node_4307));
                float2 node_4334 = (i.uv0+node_3495.g*float2(0.15,0.05));
                float4 _node_7917_var = tex2D(_node_7917,TRANSFORM_TEX(node_4334, _node_7917));
                float2 node_8212 = ((i.uv0+((_node_4307_var.r+_node_7917_var.r)*_node_4307_var.r))+node_3495.g*float2(0,0));
                float4 _node_1605_var = tex2D(_node_1605,TRANSFORM_TEX(node_8212, _node_1605));
                float3 emissive = (_node_3306*((0.25*(((((15.0*_node_8303.rgb)*pow(1.0-max(0,dot(normalDirection, viewDirection)),5.0))*2.0)+(_node_8303.rgb*1.0))*_node_3306))+(_node_1605_var.rgb*_node_5059.rgb)));
                float3 finalColor = emissive;
                fixed4 finalRGBA = fixed4(finalColor,1);
                UNITY_APPLY_FOG_COLOR(i.fogCoord, finalRGBA, fixed4(0,0,0,1));
                return finalRGBA;
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
