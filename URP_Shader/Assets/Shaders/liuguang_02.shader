// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:0,bsrc:0,bdst:0,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:True,fgod:False,fgor:False,fgmd:0,fgcr:0,fgcg:0,fgcb:0,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4795,x:32724,y:32693,varname:node_4795,prsc:2|emission-2393-OUT,alpha-7384-A;n:type:ShaderForge.SFN_Multiply,id:2393,x:32495,y:32793,varname:node_2393,prsc:2|A-7384-R,B-977-OUT;n:type:ShaderForge.SFN_Color,id:4139,x:31919,y:32868,ptovrint:False,ptlb:yanse_01,ptin:_yanse_01,varname:node_4139,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Tex2d,id:7384,x:31709,y:32635,ptovrint:False,ptlb:raodongwenli,ptin:_raodongwenli,varname:node_7384,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False|UVIN-6783-OUT,MIP-3604-OUT;n:type:ShaderForge.SFN_Panner,id:7166,x:31181,y:32614,varname:node_7166,prsc:2,spu:1,spv:1|UVIN-2858-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:3595,x:31114,y:32363,varname:node_3595,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Slider,id:3604,x:31025,y:32907,ptovrint:False,ptlb:speed,ptin:_speed,varname:node_3604,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:5;n:type:ShaderForge.SFN_Slider,id:7095,x:31919,y:33121,ptovrint:False,ptlb:yanseqingdu,ptin:_yanseqingdu,varname:node_7095,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:5;n:type:ShaderForge.SFN_Multiply,id:977,x:32241,y:32904,varname:node_977,prsc:2|A-4139-RGB,B-7095-OUT;n:type:ShaderForge.SFN_Add,id:6783,x:31401,y:32462,varname:node_6783,prsc:2|A-3595-UVOUT,B-9303-OUT;n:type:ShaderForge.SFN_Multiply,id:9303,x:31352,y:32710,varname:node_9303,prsc:2|A-7166-UVOUT,B-3604-OUT;n:type:ShaderForge.SFN_TexCoord,id:2858,x:30958,y:32556,varname:node_2858,prsc:2,uv:0,uaff:False;proporder:4139-7384-3604-7095;pass:END;sub:END;*/

Shader "Shader Forge/liuguang_01" {
    Properties {
        _yanse_01 ("yanse_01", Color) = (0.5,0.5,0.5,1)
        _raodongwenli ("raodongwenli", 2D) = "white" {}
        _speed ("speed", Range(0, 5)) = 0
        _yanseqingdu ("yanseqingdu", Range(0, 5)) = 0
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
         //   #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform float4 _yanse_01;
            uniform sampler2D _raodongwenli; uniform float4 _raodongwenli_ST;
            uniform float _speed;
            uniform float _yanseqingdu;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
////// Lighting:
////// Emissive:
                float4 node_9606 = _Time;
                float2 node_6783 = (i.uv0+((i.uv0+node_9606.g*float2(1,1))*_speed));
                float4 _raodongwenli_var = tex2Dlod(_raodongwenli,float4(TRANSFORM_TEX(node_6783, _raodongwenli),0.0,_speed));
                float3 emissive = (_raodongwenli_var.r*(_yanse_01.rgb*_yanseqingdu));
                float3 finalColor = emissive;
                fixed4 finalRGBA = fixed4(finalColor,_raodongwenli_var.a);
                UNITY_APPLY_FOG_COLOR(i.fogCoord, finalRGBA, fixed4(0,0,0,1));
                return finalRGBA;
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
