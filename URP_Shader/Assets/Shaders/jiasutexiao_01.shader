// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:3,bdst:7,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:True,fgod:False,fgor:False,fgmd:0,fgcr:0,fgcg:0,fgcb:0,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4795,x:33052,y:32772,varname:node_4795,prsc:2|emission-2393-OUT,alpha-5595-OUT;n:type:ShaderForge.SFN_Tex2d,id:6074,x:32432,y:32565,ptovrint:False,ptlb:MainTex,ptin:_MainTex,varname:_MainTex,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-1141-UVOUT;n:type:ShaderForge.SFN_Multiply,id:2393,x:32432,y:32800,varname:node_2393,prsc:2|A-6074-RGB,B-2053-RGB,C-797-RGB,D-9248-OUT;n:type:ShaderForge.SFN_VertexColor,id:2053,x:32105,y:32749,varname:node_2053,prsc:2;n:type:ShaderForge.SFN_Color,id:797,x:32105,y:32921,ptovrint:True,ptlb:Color,ptin:_TintColor,varname:_TintColor,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Vector1,id:9248,x:32235,y:33081,varname:node_9248,prsc:2,v1:3;n:type:ShaderForge.SFN_Tex2d,id:3525,x:31198,y:32582,ptovrint:False,ptlb:raodong_01,ptin:_raodong_01,varname:node_3525,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-5300-UVOUT;n:type:ShaderForge.SFN_Panner,id:5300,x:31002,y:32571,varname:node_5300,prsc:2,spu:-2,spv:0|UVIN-6368-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:6368,x:30716,y:32581,varname:node_6368,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Multiply,id:1576,x:31918,y:32699,varname:node_1576,prsc:2|A-8078-OUT,B-3562-OUT;n:type:ShaderForge.SFN_TexCoord,id:7925,x:31817,y:32395,varname:node_7925,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Add,id:711,x:32025,y:32561,varname:node_711,prsc:2|A-7925-UVOUT,B-1576-OUT;n:type:ShaderForge.SFN_Multiply,id:5595,x:32638,y:33190,varname:node_5595,prsc:2|A-6074-A,B-4194-A;n:type:ShaderForge.SFN_Multiply,id:8078,x:31665,y:32539,varname:node_8078,prsc:2|A-3525-R,B-3575-OUT;n:type:ShaderForge.SFN_Vector1,id:3575,x:31432,y:32426,varname:node_3575,prsc:2,v1:0.2;n:type:ShaderForge.SFN_Multiply,id:3562,x:31537,y:32814,varname:node_3562,prsc:2|A-3525-R,B-5744-OUT;n:type:ShaderForge.SFN_Vector1,id:5744,x:31364,y:32871,varname:node_5744,prsc:2,v1:0.1;n:type:ShaderForge.SFN_Panner,id:1141,x:32195,y:32454,varname:node_1141,prsc:2,spu:-3,spv:0|UVIN-711-OUT;n:type:ShaderForge.SFN_Tex2d,id:4194,x:32293,y:33421,ptovrint:False,ptlb:touming,ptin:_touming,varname:node_4194,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;proporder:6074-797-3525-4194;pass:END;sub:END;*/

Shader "Shader Forge/jiasutexiao_01" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        _raodong_01 ("raodong_01", 2D) = "white" {}
        _touming ("touming", 2D) = "white" {}
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_speed("speed",float) = 1
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
                "RenderPipeline" = "UniversalPipeline"
            }
            Blend SrcAlpha OneMinusSrcAlpha
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
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float4 _TintColor;
            uniform sampler2D _raodong_01; uniform float4 _raodong_01_ST;
            uniform sampler2D _touming; uniform float4 _touming_ST;
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
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
////// Lighting:
////// Emissive:
                float4 node_6928 = _Time * _speed;
                float2 node_5300 = (i.uv0+node_6928.g*float2(-2,0));
                float4 _raodong_01_var = tex2D(_raodong_01,TRANSFORM_TEX(node_5300, _raodong_01));
                float2 node_1141 = ((i.uv0+((_raodong_01_var.r*0.2)*(_raodong_01_var.r*0.1)))+node_6928.g*float2(-3,0));
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(node_1141, _MainTex));
                float3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*3.0);
                float3 finalColor = emissive;
                float4 _touming_var = tex2D(_touming,TRANSFORM_TEX(i.uv0, _touming));
                fixed4 finalRGBA = fixed4(finalColor,(_MainTex_var.a*_touming_var.a));
                UNITY_APPLY_FOG_COLOR(i.fogCoord, finalRGBA, fixed4(0,0,0,1));
                return finalRGBA;
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
