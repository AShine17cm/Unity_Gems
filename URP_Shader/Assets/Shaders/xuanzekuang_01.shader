// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:0,bdst:0,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:True,fgod:False,fgor:False,fgmd:0,fgcr:0,fgcg:0,fgcb:0,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4795,x:32977,y:32724,varname:node_4795,prsc:2|custl-2742-OUT;n:type:ShaderForge.SFN_Fresnel,id:277,x:31983,y:32836,varname:node_277,prsc:2;n:type:ShaderForge.SFN_Power,id:4140,x:32275,y:32852,varname:node_4140,prsc:2|VAL-277-OUT,EXP-938-OUT;n:type:ShaderForge.SFN_Exp,id:938,x:32122,y:32994,varname:node_938,prsc:2,et:0|IN-4936-OUT;n:type:ShaderForge.SFN_Slider,id:4936,x:31693,y:32990,ptovrint:False,ptlb:bianyuankuandu_01,ptin:_bianyuankuandu_01,varname:node_4936,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:2;n:type:ShaderForge.SFN_DepthBlend,id:9150,x:32229,y:33196,varname:node_9150,prsc:2|DIST-6689-OUT;n:type:ShaderForge.SFN_RemapRange,id:6689,x:32000,y:33196,varname:node_6689,prsc:2,frmn:0,frmx:1,tomn:1,tomx:-1|IN-2436-OUT;n:type:ShaderForge.SFN_OneMinus,id:3866,x:32413,y:33208,varname:node_3866,prsc:2|IN-9150-OUT;n:type:ShaderForge.SFN_Add,id:8317,x:32514,y:32946,varname:node_8317,prsc:2|A-4140-OUT,B-2091-OUT;n:type:ShaderForge.SFN_Multiply,id:2742,x:32693,y:32837,varname:node_2742,prsc:2|A-4648-RGB,B-8317-OUT;n:type:ShaderForge.SFN_Color,id:4648,x:32395,y:32698,ptovrint:False,ptlb:node_4648,ptin:_node_4648,varname:node_4648,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Multiply,id:2091,x:32666,y:33171,varname:node_2091,prsc:2|A-3866-OUT,B-5810-OUT;n:type:ShaderForge.SFN_ValueProperty,id:5810,x:32506,y:33364,ptovrint:False,ptlb:bianyuanliangdu_01,ptin:_bianyuanliangdu_01,varname:node_5810,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:1;n:type:ShaderForge.SFN_Slider,id:2436,x:31665,y:33196,ptovrint:False,ptlb:qixiankuandu_01,ptin:_qixiankuandu_01,varname:node_2436,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:-1,cur:0.46,max:1;proporder:4936-4648-5810-2436;pass:END;sub:END;*/

Shader "Shader Forge/xuanzekuang_01" {
    Properties {
        _bianyuankuandu_01 ("bianyuankuandu_01", Range(0, 2)) = 1
        _node_4648 ("node_4648", Color) = (0.5,0.5,0.5,1)
        _bianyuanliangdu_01 ("bianyuanliangdu_01", Float ) = 1
        _qixiankuandu_01 ("qixiankuandu_01", Range(-1, 1)) = 0.46
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
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform sampler2D _CameraDepthTexture;
            uniform float _bianyuankuandu_01;
            uniform float4 _node_4648;
            uniform float _bianyuanliangdu_01;
            uniform float _qixiankuandu_01;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                float4 projPos : TEXCOORD2;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                i.normalDir *= faceSign;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
////// Lighting:
                float3 finalColor = (_node_4648.rgb*(pow((1.0-max(0,dot(normalDirection, viewDirection))),exp(_bianyuankuandu_01))+((1.0 - saturate((sceneZ-partZ)/(_qixiankuandu_01*-2.0+1.0)))*_bianyuanliangdu_01)));
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
