// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASE/jiguang_01"
{
	Properties
	{
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_time("time", Float) = 15
		_Columns("Columns", Float) = 4
		_Rows("Rows", Float) = 4
		_Speed("Speed", Float) = 1
		[HDR]_Color("Color", Color) = (1,1,1,0)
		_Usped("Usped", Float) = 0
		_Vspeed("Vspeed", Float) = 0
		[Toggle(_XULIEZHEN_01_ON)] _xuliezhen_01("xuliezhen_01", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha , One One
		Cull Back
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "RenderPipeline" = "UniversalPipeline" }
			CGPROGRAM

				 #pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#pragma shader_feature_local _XULIEZHEN_01_ON


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				float4 ase_texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord : TEXCOORD0;
			};

			uniform float4 _Color;
			uniform sampler2D _TextureSample0;
			uniform float _Usped;
			uniform float _Vspeed;
			uniform float4 _TextureSample0_ST;
			uniform float _Columns;
			uniform float _Rows;
			uniform float _Speed;
			uniform float _time;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				float2 appendResult37 = (float2(_Usped , _Vspeed));
				float2 uv0_TextureSample0 = i.ase_texcoord.xy * _TextureSample0_ST.xy + _TextureSample0_ST.zw;
				float mulTime23 = _Time.y * _Speed;
				// *** BEGIN Flipbook UV Animation vars ***
				// Total tiles of Flipbook Texture
				float fbtotaltiles26 = _Columns * _Rows;
				// Offsets for cols and rows of Flipbook Texture
				float fbcolsoffset26 = 1.0f / _Columns;
				float fbrowsoffset26 = 1.0f / _Rows;
				// Speed of animation
				float fbspeed26 = mulTime23 * 1.0;
				// UV Tiling (col and row offset)
				float2 fbtiling26 = float2(fbcolsoffset26, fbrowsoffset26);
				// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
				// Calculate current tile linear index
				float fbcurrenttileindex26 = round( fmod( fbspeed26 + 0.0, fbtotaltiles26) );
				fbcurrenttileindex26 += ( fbcurrenttileindex26 < 0) ? fbtotaltiles26 : 0;
				// Obtain Offset X coordinate from current tile linear index
				float fblinearindextox26 = round ( fmod ( fbcurrenttileindex26, _Columns ) );
				// Multiply Offset X by coloffset
				float fboffsetx26 = fblinearindextox26 * fbcolsoffset26;
				// Obtain Offset Y coordinate from current tile linear index
				float fblinearindextoy26 = round( fmod( ( fbcurrenttileindex26 - fblinearindextox26 ) / _Columns, _Rows ) );
				// Reverse Y to get tiles from Top to Bottom
				fblinearindextoy26 = (int)(_Rows-1) - fblinearindextoy26;
				// Multiply Offset Y by rowoffset
				float fboffsety26 = fblinearindextoy26 * fbrowsoffset26;
				// UV Offset
				float2 fboffset26 = float2(fboffsetx26, fboffsety26);
				// Flipbook UV
				half2 fbuv26 = frac( uv0_TextureSample0 ) * fbtiling26 + fboffset26;
				// *** END Flipbook UV Animation vars ***
				#ifdef _XULIEZHEN_01_ON
				float2 staticSwitch39 = fbuv26;
				#else
				float2 staticSwitch39 = uv0_TextureSample0;
				#endif
				float2 panner34 = ( 1.0 * _Time.y * appendResult37 + staticSwitch39);
				float4 tex2DNode1 = tex2D( _TextureSample0, panner34 );
				float mulTime13 = _Time.y * _time;
				float clampResult38 = clamp( cos( mulTime13 ) , 0.0 , 1.0 );
				float4 appendResult40 = (float4((( _Color * tex2DNode1 )).rgb , ( tex2DNode1.a * clampResult38 * _Color.a )));
				
				
				finalColor = appendResult40;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=17500
2148;302;1300;532;1275.883;716.9368;1.690674;True;False
Node;AmplifyShaderEditor.RangedFloatNode;22;-1903.92,-254.1048;Inherit;False;Property;_Speed;Speed;5;0;Create;True;0;0;False;0;1;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;20;-1871.446,-692.0795;Inherit;True;0;1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;23;-1712.822,-248.9046;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-1709.468,-369.2985;Inherit;False;Property;_Rows;Rows;4;0;Create;True;0;0;False;0;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-1704.269,-444.6983;Inherit;False;Property;_Columns;Columns;3;0;Create;True;0;0;False;0;4;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;21;-1527.951,-672.9907;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-1229.653,-665.2863;Inherit;False;Property;_Vspeed;Vspeed;8;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-1268.142,-760.0584;Inherit;False;Property;_Usped;Usped;7;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;26;-1418.779,-422.1845;Inherit;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;4;False;2;FLOAT;4;False;3;FLOAT;1;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.StaticSwitch;39;-1130,-557.2197;Inherit;False;Property;_xuliezhen_01;xuliezhen_01;9;0;Create;True;0;0;False;0;0;0;1;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-1288.609,-131.3677;Inherit;False;Property;_time;time;2;0;Create;True;0;0;False;0;15;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;37;-988.5046,-704.1812;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;34;-837.6188,-570.9759;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;13;-1064.398,-105.6947;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;14;-824.7828,-110.8293;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;32;-537.727,-620.0464;Inherit;False;Property;_Color;Color;6;1;[HDR];Create;True;0;0;False;0;1,1,1,0;2,2,2,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;1;-561.3238,-286.914;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;-1;None;8220238f8cdc3c84dac6e06dc1310cd2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-220.643,-421.3672;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;38;187.8475,-30.46387;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;334.6547,-214.8055;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;29;16.20465,-454.6377;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;40;473.5383,-439.8002;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;43;677.8851,-438.1532;Float;False;True;-1;2;ASEMaterialInspector;100;1;ASE/jiguang_01;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;2;5;False;-1;10;False;-1;4;1;False;-1;1;False;-1;True;0;False;-1;0;False;-1;True;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;0;False;-1;True;False;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;0
WireConnection;23;0;22;0
WireConnection;21;0;20;0
WireConnection;26;0;21;0
WireConnection;26;1;24;0
WireConnection;26;2;25;0
WireConnection;26;5;23;0
WireConnection;39;1;20;0
WireConnection;39;0;26;0
WireConnection;37;0;35;0
WireConnection;37;1;36;0
WireConnection;34;0;39;0
WireConnection;34;2;37;0
WireConnection;13;0;15;0
WireConnection;14;0;13;0
WireConnection;1;1;34;0
WireConnection;31;0;32;0
WireConnection;31;1;1;0
WireConnection;38;0;14;0
WireConnection;33;0;1;4
WireConnection;33;1;38;0
WireConnection;33;2;32;4
WireConnection;29;0;31;0
WireConnection;40;0;29;0
WireConnection;40;3;33;0
WireConnection;43;0;40;0
ASEEND*/
//CHKSM=C74F02D65709CA24F2D88A09E5A3F3E4846710C0