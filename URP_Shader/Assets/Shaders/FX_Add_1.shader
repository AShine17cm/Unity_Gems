// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Yo/Add_1"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_Extrusion("Extrusion", Float) = 1
		[HDR]_Color("Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white" {}
		_MainRota("MainRota", Float) = 0
		[Toggle]_MainPolar("MainPolar", Float) = 0
		_Main_U_Offset("Main_U_Offset", Float) = 0
		_Main_V_Offset("Main_V_Offset", Float) = 0
		_Main_U_Speed("Main_U_Speed", Float) = 0
		_Main_V_Speed("Main_V_Speed", Float) = 0
		_Mask("Mask", 2D) = "white" {}
		_MaskIntensity("MaskIntensity", Float) = 1.76
		_MaskRota("MaskRota", Float) = 0
		[Toggle]_MaskPolar("MaskPolar", Float) = 0
		_Mask_U_Speed("Mask_U_Speed", Float) = 0
		_Mask_V_Speed("Mask_V_Speed", Float) = 0
		_PannerTex("PannerTex", 2D) = "white" {}
		_PannerIntensity("PannerIntensity", Float) = 0
		_PannerRota("PannerRota", Float) = 0
		[Toggle]_PannerPolar("PannerPolar", Float) = 0
		_Panner_U_Speed("Panner_U_Speed", Float) = 0
		_Panner_V_Speed("Panner_V_Speed", Float) = 0
		_DissloveTex("DissloveTex", 2D) = "white" {}
		_Hardness("Hardness", Range( 0 , 1)) = 1
		_Edgewidth("Edgewidth", Range( 0 , 1)) = 0
		[HDR]_EdgeColor("EdgeColor", Color) = (1,0,0,1)
		_DissloveIntensity("DissloveIntensity", Range( 0 , 1)) = 0.02629435
		_Diss_U_Speed("Diss_U_Speed", Float) = 0
		_Diss_V_Speed("Diss_V_Speed", Float) = 0
		_DissRota("DissRota", Float) = 0
		[Toggle]_DissPolar("DissPolar", Float) = 0
		_Offset("Offset", 2D) = "white" {}
		_OffsetIntensity("OffsetIntensity", Float) = 0
		_OffsetRota("OffsetRota", Float) = 0
		[Toggle]_OffsetPolar("OffsetPolar", Float) = 0
		_Offset_U_Speed("Offset_U_Speed", Float) = 0
		_Offset_V_Speed("Offset_V_Speed", Float) = 0
		[Enum(Particle,0,Model,1)]_Mode("Mode", Float) = 0

		[HideInInspector]_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		[HideInInspector]_TessMin( "Tess Min Distance", Float ) = 10
		[HideInInspector]_TessMax( "Tess Max Distance", Float ) = 25
		[HideInInspector]_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		[HideInInspector]_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
		
		Cull Off
		HLSLINCLUDE
		#pragma target 2.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One One , One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_COLOR


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;

				half4  mask : TEXCOORD5; 

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _EdgeColor;
			float4 _MainTex_ST;
			float4 _DissloveTex_ST;
			float4 _PannerTex_ST;
			half4 _Color;
			float4 _Offset_ST;
			float4 _Mask_ST;
			half _Mask_V_Speed;
			half _Mask_U_Speed;
			half _PannerRota;
			half _Main_U_Speed;
			half _Panner_V_Speed;
			half _Panner_U_Speed;
			half _MainRota;
			half _MaskRota;
			half _MainPolar;
			half _Main_V_Speed;
			half _MaskPolar;
			half _PannerPolar;
			half _Hardness;
			half _Edgewidth;
			half _Offset_V_Speed;
			half _OffsetPolar;
			half _OffsetRota;
			half _Extrusion;
			half _OffsetIntensity;
			half _Diss_U_Speed;
			half _MaskIntensity;
			half _Diss_V_Speed;
			half _DissRota;
			half _Main_U_Offset;
			half _Main_V_Offset;
			half _DissloveIntensity;
			half _PannerIntensity;
			float _Mode;
			half _DissPolar;
			half _Offset_U_Speed;
			float _TessPhongStrength;
			float _TessValue;
			float _TessMin;
			float _TessMax;
			float _TessEdgeLength;
			float _TessMaxDisp;
			CBUFFER_END
			sampler2D _Offset;
			sampler2D _DissloveTex;
			sampler2D _MainTex;
			sampler2D _PannerTex;
			sampler2D _Mask;

			float4 _ClipRect;

						
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 appendResult38 = (float2(_Offset_U_Speed , _Offset_V_Speed));
				float2 uv0_Offset = v.ase_texcoord.xy * _Offset_ST.xy + _Offset_ST.zw;
				float cos62 = cos( _OffsetRota );
				float sin62 = sin( _OffsetRota );
				float2 rotator62 = mul( uv0_Offset - float2( 0.5,0.5 ) , float2x2( cos62 , -sin62 , sin62 , cos62 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g4 = (rotator62*2.0 + -1.0);
				float2 break3_g4 = temp_output_2_0_g4;
				float2 appendResult8_g4 = (float2(pow( length( temp_output_2_0_g4 ) , _Extrusion ) , ( ( atan2( break3_g4.y , break3_g4.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner37 = ( 1.0 * _Time.y * appendResult38 + (( _OffsetPolar )?( appendResult8_g4 ):( rotator62 )));
				float3 temp_cast_0 = (( tex2Dlod( _Offset, float4( panner37, 0, 0.0) ).r * _OffsetIntensity )).xxx;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;

				//RECT MASK 2D
                float2 pixelSize = float2(1, 1) / abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));
                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                o.mask = half4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / abs(pixelSize.xy));
                //RECT MASK 2D END

				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_color = v.ase_color;


				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				//RECT MASK 2D
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                clip(m.x * m.y - 0.001);
                //RECT MASK 2D END

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 appendResult145 = (float2(_Diss_U_Speed , _Diss_V_Speed));
				float2 uv0_DissloveTex = IN.ase_texcoord3.xy * _DissloveTex_ST.xy + _DissloveTex_ST.zw;
				float cos143 = cos( _DissRota );
				float sin143 = sin( _DissRota );
				float2 rotator143 = mul( uv0_DissloveTex - float2( 0.5,0.5 ) , float2x2( cos143 , -sin143 , sin143 , cos143 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g30 = (rotator143*2.0 + -1.0);
				float2 break3_g30 = temp_output_2_0_g30;
				float2 appendResult8_g30 = (float2(pow( length( temp_output_2_0_g30 ) , _Extrusion ) , ( ( atan2( break3_g30.y , break3_g30.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner144 = ( 1.0 * _Time.y * appendResult145 + (( _DissPolar )?( appendResult8_g30 ):( rotator143 )));
				float temp_output_103_0 = ( tex2D( _DissloveTex, panner144 ).r + 1.0 );
				float4 uv1147 = IN.ase_texcoord4;
				uv1147.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult164 = (float4(_Main_U_Offset , _Main_V_Offset , _DissloveIntensity , _PannerIntensity));
				float4 lerpResult160 = lerp( uv1147 , appendResult164 , _Mode);
				float4 break161 = lerpResult160;
				float temp_output_127_0 = ( break161.z * ( 1.0 + _Edgewidth ) );
				half Hardness129 = _Hardness;
				float temp_output_112_0 = ( 1.0 - Hardness129 );
				float temp_output_10_0_g32 = _Hardness;
				float2 appendResult14 = (float2(_Main_U_Speed , _Main_V_Speed));
				float2 uv0_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float temp_output_4_0_g29 = 1.0;
				float temp_output_5_0_g29 = 1.0;
				float2 appendResult7_g29 = (float2(temp_output_4_0_g29 , temp_output_5_0_g29));
				float totalFrames39_g29 = ( temp_output_4_0_g29 * temp_output_5_0_g29 );
				float2 appendResult8_g29 = (float2(totalFrames39_g29 , temp_output_5_0_g29));
				float clampResult42_g29 = clamp( 0.0 , 0.0001 , ( totalFrames39_g29 - 1.0 ) );
				float temp_output_35_0_g29 = frac( ( ( _TimeParameters.x + clampResult42_g29 ) / totalFrames39_g29 ) );
				float2 appendResult29_g29 = (float2(temp_output_35_0_g29 , ( 1.0 - temp_output_35_0_g29 )));
				float2 temp_output_15_0_g29 = ( ( uv0_MainTex / appendResult7_g29 ) + ( floor( ( appendResult8_g29 * appendResult29_g29 ) ) / appendResult7_g29 ) );
				float2 break158 = temp_output_15_0_g29;
				float2 appendResult152 = (float2(( break161.x + break158.x ) , ( break158.y + break161.y )));
				float cos44 = cos( _MainRota );
				float sin44 = sin( _MainRota );
				float2 rotator44 = mul( appendResult152 - float2( 0.5,0.5 ) , float2x2( cos44 , -sin44 , sin44 , cos44 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g27 = (rotator44*2.0 + -1.0);
				float2 break3_g27 = temp_output_2_0_g27;
				float2 appendResult8_g27 = (float2(pow( length( temp_output_2_0_g27 ) , _Extrusion ) , ( ( atan2( break3_g27.y , break3_g27.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner16 = ( 1.0 * _Time.y * appendResult14 + (( _MainPolar )?( appendResult8_g27 ):( rotator44 )));
				float2 appendResult21 = (float2(_Panner_U_Speed , _Panner_V_Speed));
				float2 uv0_PannerTex = IN.ase_texcoord3.xy * _PannerTex_ST.xy + _PannerTex_ST.zw;
				float cos53 = cos( _PannerRota );
				float sin53 = sin( _PannerRota );
				float2 rotator53 = mul( uv0_PannerTex - float2( 0.5,0.5 ) , float2x2( cos53 , -sin53 , sin53 , cos53 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g33 = (rotator53*2.0 + -1.0);
				float2 break3_g33 = temp_output_2_0_g33;
				float2 appendResult8_g33 = (float2(pow( length( temp_output_2_0_g33 ) , _Extrusion ) , ( ( atan2( break3_g33.y , break3_g33.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner20 = ( 1.0 * _Time.y * appendResult21 + (( _PannerPolar )?( appendResult8_g33 ):( rotator53 )));
				float4 tex2DNode6 = tex2D( _MainTex, ( panner16 + ( tex2D( _PannerTex, panner20 ).r * break161.w ) ) );
				float2 appendResult31 = (float2(_Mask_U_Speed , _Mask_V_Speed));
				float2 uv0_Mask = IN.ase_texcoord3.xy * _Mask_ST.xy + _Mask_ST.zw;
				float cos57 = cos( _MaskRota );
				float sin57 = sin( _MaskRota );
				float2 rotator57 = mul( uv0_Mask - float2( 0.5,0.5 ) , float2x2( cos57 , -sin57 , sin57 , cos57 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g28 = (rotator57*2.0 + -1.0);
				float2 break3_g28 = temp_output_2_0_g28;
				float2 appendResult8_g28 = (float2(pow( length( temp_output_2_0_g28 ) , _Extrusion ) , ( ( atan2( break3_g28.y , break3_g28.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner32 = ( 1.0 * _Time.y * appendResult31 + (( _MaskPolar )?( appendResult8_g28 ):( rotator57 )));
				float4 tex2DNode28 = tex2D( _Mask, panner32 );
				float temp_output_10_0_g31 = _Hardness;
				float4 lerpResult123 = lerp( _EdgeColor , ( _Color * tex2DNode6 * IN.ase_color ) , saturate( ( ( ( temp_output_103_0 - ( temp_output_127_0 * ( 1.0 + temp_output_112_0 ) ) ) - temp_output_10_0_g31 ) / ( 1.0 - temp_output_10_0_g31 ) ) ));
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( saturate( ( ( ( temp_output_103_0 - ( ( temp_output_127_0 - _Edgewidth ) * ( 1.0 + temp_output_112_0 ) ) ) - temp_output_10_0_g32 ) / ( 1.0 - temp_output_10_0_g32 ) ) ) * _Color.a * tex2DNode6.a * IN.ase_color.a * ( tex2DNode28.r * tex2DNode28.a * _MaskIntensity ) * lerpResult123 ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#define _RECEIVE_SHADOWS_OFF 1
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _EdgeColor;
			float4 _MainTex_ST;
			float4 _DissloveTex_ST;
			float4 _PannerTex_ST;
			half4 _Color;
			float4 _Offset_ST;
			float4 _Mask_ST;
			half _Mask_V_Speed;
			half _Mask_U_Speed;
			half _PannerRota;
			half _Main_U_Speed;
			half _Panner_V_Speed;
			half _Panner_U_Speed;
			half _MainRota;
			half _MaskRota;
			half _MainPolar;
			half _Main_V_Speed;
			half _MaskPolar;
			half _PannerPolar;
			half _Hardness;
			half _Edgewidth;
			half _Offset_V_Speed;
			half _OffsetPolar;
			half _OffsetRota;
			half _Extrusion;
			half _OffsetIntensity;
			half _Diss_U_Speed;
			half _MaskIntensity;
			half _Diss_V_Speed;
			half _DissRota;
			half _Main_U_Offset;
			half _Main_V_Offset;
			half _DissloveIntensity;
			half _PannerIntensity;
			float _Mode;
			half _DissPolar;
			half _Offset_U_Speed;
			float _TessPhongStrength;
			float _TessValue;
			float _TessMin;
			float _TessMax;
			float _TessEdgeLength;
			float _TessMaxDisp;
			CBUFFER_END
			sampler2D _Offset;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float2 appendResult38 = (float2(_Offset_U_Speed , _Offset_V_Speed));
				float2 uv0_Offset = v.ase_texcoord.xy * _Offset_ST.xy + _Offset_ST.zw;
				float cos62 = cos( _OffsetRota );
				float sin62 = sin( _OffsetRota );
				float2 rotator62 = mul( uv0_Offset - float2( 0.5,0.5 ) , float2x2( cos62 , -sin62 , sin62 , cos62 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g4 = (rotator62*2.0 + -1.0);
				float2 break3_g4 = temp_output_2_0_g4;
				float2 appendResult8_g4 = (float2(pow( length( temp_output_2_0_g4 ) , _Extrusion ) , ( ( atan2( break3_g4.y , break3_g4.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner37 = ( 1.0 * _Time.y * appendResult38 + (( _OffsetPolar )?( appendResult8_g4 ):( rotator62 )));
				float3 temp_cast_0 = (( tex2Dlod( _Offset, float4( panner37, 0, 0.0) ).r * _OffsetIntensity )).xxx;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = temp_cast_0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18100
-1920;31;1920;965;4294.275;2390.804;3.166468;True;False
Node;AmplifyShaderEditor.CommentaryNode;67;-2239.093,739.7263;Inherit;False;1973.199;507.98;顶点偏移;12;36;43;37;38;60;61;39;41;62;40;63;42;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-2074.64,996.2251;Half;False;Property;_OffsetRota;OffsetRota;33;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;40;-2223.2,844.0706;Inherit;False;0;36;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RotatorNode;62;-1869.703,845.3419;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-1461.503,1068.229;Half;False;Property;_Offset_U_Speed;Offset_U_Speed;35;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-1461.502,1154.029;Half;False;Property;_Offset_V_Speed;Offset_V_Speed;36;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;61;-1629.704,779.0475;Inherit;False;Polat Coordiates;0;;4;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;38;-1243.102,1107.228;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;60;-1320.357,838.5551;Half;True;Property;_OffsetPolar;OffsetPolar;34;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;37;-1008.303,895.5302;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;146;-3215.578,-2034.749;Inherit;False;3724.288;880.3489;溶解;29;123;116;111;145;101;142;100;114;141;140;143;144;119;94;103;109;138;129;137;117;110;127;126;112;105;130;139;128;122;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;65;-2659.726,-203.2679;Inherit;False;1872.837;463.0843;扰动;11;20;54;52;18;55;53;23;25;21;19;22;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-654.222,1082.763;Half;False;Property;_OffsetIntensity;OffsetIntensity;32;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;66;-2321.782,273.3164;Inherit;False;2058.345;459.5582;遮罩;12;32;33;29;31;30;58;57;59;56;34;35;28;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;64;-2467.956,-916.4207;Inherit;False;1448.3;488.7537;UV流动;6;12;46;48;45;44;16;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;36;-765.473,866.2864;Inherit;True;Property;_Offset;Offset;31;0;Create;True;0;0;False;0;False;-1;c01fa92039faa084987c37588b7a59ca;c01fa92039faa084987c37588b7a59ca;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;54;-1726.192,-122.4312;Half;True;Property;_PannerPolar;PannerPolar;19;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;122;-1358.134,-1266.954;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;46;-1869.563,-810.7401;Inherit;False;Polat Coordiates;0;;27;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;18;-1187.498,-89.67829;Inherit;True;Property;_PannerTex;PannerTex;16;0;Create;True;0;0;False;0;False;-1;1310c389b00742944a196851ef347845;1310c389b00742944a196851ef347845;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;-1204.733,-1338.554;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-1857.568,100.2113;Half;False;Property;_Panner_U_Speed;Panner_U_Speed;20;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-412.1716,408.9169;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;-410.8872,897.7734;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;53;-2352.53,-120.7682;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;117;-2061.761,-1413.422;Half;False;Property;_Edgewidth;Edgewidth;24;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;28;-879.3273,379.3917;Inherit;True;Property;_Mask;Mask;10;0;Create;True;0;0;False;0;False;-1;1310c389b00742944a196851ef347845;8c4a7fca2884fab419769ccc0355c0c1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;136;759.4407,-987.3904;Inherit;False;6;6;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;26;-4464.318,-722.1107;Half;False;Property;_PannerIntensity;PannerIntensity;17;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;58;-1725.458,300.7817;Inherit;False;Polat Coordiates;0;;28;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;128;-1722.451,-1477.595;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-3007.595,-1704.443;Half;False;Property;_DissRota;DissRota;29;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-389.7802,-693.6807;Half;False;Property;_Color;Color;2;1;[HDR];Create;True;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;94;-400.3371,-1996.099;Half;False;Property;_EdgeColor;EdgeColor;25;1;[HDR];Create;True;0;0;False;0;False;1,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;31;-1378.257,591.9712;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;148;-4210.606,-739.0323;Inherit;False;Property;_Mode;Mode;37;1;[Enum];Create;True;2;Particle;0;Model;1;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;165;-3211.922,-833.0005;Inherit;False;Flipbook;-1;;29;53c2488c220f6564ca6c90721ee16673;2,71,1,68,0;8;51;SAMPLER2D;0.0;False;13;FLOAT2;0,0;False;4;FLOAT;1;False;5;FLOAT;1;False;24;FLOAT;0;False;2;FLOAT;0;False;55;FLOAT;0;False;70;FLOAT;0;False;5;COLOR;53;FLOAT2;0;FLOAT;47;FLOAT;48;FLOAT;62
Node;AmplifyShaderEditor.TextureCoordinatesNode;19;-2626.312,-162.7998;Inherit;False;0;18;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;45;-2316.832,-611.0704;Half;False;Property;_MainRota;MainRota;4;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;163;-4446.368,-912.1247;Half;False;Property;_Main_V_Offset;Main_V_Offset;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-1590.039,-462.884;Half;False;Property;_Main_U_Speed;Main_U_Speed;8;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;16;-1215.276,-756.5102;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;147;-4290.44,-1165.945;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;141;-3081.643,-1870.299;Inherit;False;0;100;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;30;-2239.486,317.9447;Inherit;False;0;28;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-902.4015,17.71451;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;162;-4454.368,-1003.125;Half;False;Property;_Main_U_Offset;Main_U_Offset;6;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-1214.821,-1635.339;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-1770.31,-1314.303;Inherit;False;129;Hardness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;9;-346.7802,-292.6801;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-1551.451,-1634.595;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-2170.395,488.4307;Half;False;Property;_MaskRota;MaskRota;12;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-669.5583,-280.2903;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;7;-3347.574,-1043.07;Inherit;False;0;6;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;14;-1355.689,-402.7496;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;160;-3902.766,-1062.324;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;164;-4227.365,-977.2568;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;102;-4551.25,-818.0911;Half;False;Property;_DissloveIntensity;DissloveIntensity;26;0;Create;True;0;0;False;0;False;0.02629435;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;137;-2165.125,-1876.713;Half;True;Property;_DissPolar;DissPolar;30;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;44;-2109.563,-762.7401;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;152;-2531.589,-1013.773;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-2385.761,-1699.227;Half;False;Property;_Diss_U_Speed;Diss_U_Speed;27;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;100;-1385.443,-1834.693;Inherit;True;Property;_DissloveTex;DissloveTex;22;0;Create;True;0;0;False;0;False;-1;097128b85d624d749838b48850d0972d;097128b85d624d749838b48850d0972d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;112;-1591.821,-1308.339;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-766.8345,-1549.575;Half;False;Property;_Hardness;Hardness;23;0;Create;True;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;6;-472.7803,-502.6801;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;False;0;False;6;84508b93f15f2b64386ec07486afc7a3;84508b93f15f2b64386ec07486afc7a3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;59;-1416.111,360.2892;Half;True;Property;_MaskPolar;MaskPolar;13;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;20;-1407.979,-37.33461;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-758.1296,615.8253;Half;False;Property;_MaskIntensity;MaskIntensity;11;0;Create;True;0;0;False;0;False;1.76;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;139;-2390.626,-1608.994;Half;False;Property;_Diss_V_Speed;Diss_V_Speed;28;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;-448.3228,-1546.539;Half;False;Hardness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;111;-1364.221,-1555.739;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-2557.466,0.5862699;Half;False;Property;_PannerRota;PannerRota;18;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;32;-1111.756,408.9167;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-1857.567,186.0111;Half;False;Property;_Panner_V_Speed;Panner_V_Speed;21;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;123;152.9161,-1609.834;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;21;-1639.168,139.2111;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;161;-3705.867,-1061.502;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;33;-1596.658,552.9713;Half;False;Property;_Mask_U_Speed;Mask_U_Speed;14;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;126;-1366.801,-1434.376;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;29;-1596.657,638.7713;Half;False;Property;_Mask_V_Speed;Mask_V_Speed;15;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;140;-2501.125,-1913.713;Inherit;False;Polat Coordiates;0;;30;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-1594.904,-372.6516;Half;False;Property;_Main_V_Speed;Main_V_Speed;9;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;103;-989.864,-1804.443;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;150;-2681.708,-1073.82;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;119;-742.7758,-1396.658;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;145;-2151.41,-1639.092;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;109;-434.8342,-1799.575;Inherit;True;SmoothStep;-1;;31;1aab39c3f78b8e24a8943d8e8e34fbc4;0;3;9;FLOAT;0;False;10;FLOAT;0;False;11;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;57;-1965.457,367.0761;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;-43.90009,-521.491;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;101;-728.8643,-1800.443;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;144;-1828.696,-1803.753;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;48;-1517.563,-762.7401;Half;True;Property;_MainPolar;MainPolar;5;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;116;-432.7466,-1389.79;Inherit;True;SmoothStep;-1;;32;1aab39c3f78b8e24a8943d8e8e34fbc4;0;3;9;FLOAT;0;False;10;FLOAT;0;False;11;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;158;-3036.471,-1047.519;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.FunctionNode;52;-2076.528,-187.0625;Inherit;False;Polat Coordiates;0;;33;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;143;-2741.125,-1865.713;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;154;-2687.918,-975.4675;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;120.0721,-545.2213;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;87,-274;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;True;2;False;-1;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;87,-274;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;87,-274;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;1111.51,-992.6499;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Yo/Add;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;7;False;False;False;True;2;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;0;True;1;1;False;-1;1;False;-1;1;1;False;-1;10;False;-1;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;21;Surface;1;  Blend;2;Two Sided;0;Cast Shadows;0;Receive Shadows;0;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;True;False;False;;0
WireConnection;62;0;40;0
WireConnection;62;2;63;0
WireConnection;61;12;62;0
WireConnection;38;0;41;0
WireConnection;38;1;39;0
WireConnection;60;0;62;0
WireConnection;60;1;61;0
WireConnection;37;0;60;0
WireConnection;37;2;38;0
WireConnection;36;1;37;0
WireConnection;54;0;53;0
WireConnection;54;1;52;0
WireConnection;122;1;112;0
WireConnection;46;12;44;0
WireConnection;18;1;20;0
WireConnection;114;0;126;0
WireConnection;114;1;122;0
WireConnection;34;0;28;1
WireConnection;34;1;28;4
WireConnection;34;2;35;0
WireConnection;42;0;36;1
WireConnection;42;1;43;0
WireConnection;53;0;19;0
WireConnection;53;2;55;0
WireConnection;28;1;32;0
WireConnection;136;0;116;0
WireConnection;136;1;10;4
WireConnection;136;2;6;4
WireConnection;136;3;9;4
WireConnection;136;4;34;0
WireConnection;136;5;123;0
WireConnection;58;12;57;0
WireConnection;128;1;117;0
WireConnection;31;0;33;0
WireConnection;31;1;29;0
WireConnection;165;13;7;0
WireConnection;16;0;48;0
WireConnection;16;2;14;0
WireConnection;25;0;18;1
WireConnection;25;1;161;3
WireConnection;105;0;127;0
WireConnection;105;1;111;0
WireConnection;127;0;161;2
WireConnection;127;1;128;0
WireConnection;24;0;16;0
WireConnection;24;1;25;0
WireConnection;14;0;12;0
WireConnection;14;1;13;0
WireConnection;160;0;147;0
WireConnection;160;1;164;0
WireConnection;160;2;148;0
WireConnection;164;0;162;0
WireConnection;164;1;163;0
WireConnection;164;2;102;0
WireConnection;164;3;26;0
WireConnection;137;0;143;0
WireConnection;137;1;140;0
WireConnection;44;0;152;0
WireConnection;44;2;45;0
WireConnection;152;0;150;0
WireConnection;152;1;154;0
WireConnection;100;1;144;0
WireConnection;112;0;130;0
WireConnection;6;1;24;0
WireConnection;59;0;57;0
WireConnection;59;1;58;0
WireConnection;20;0;54;0
WireConnection;20;2;21;0
WireConnection;129;0;110;0
WireConnection;111;1;112;0
WireConnection;32;0;59;0
WireConnection;32;2;31;0
WireConnection;123;0;94;0
WireConnection;123;1;91;0
WireConnection;123;2;109;0
WireConnection;21;0;22;0
WireConnection;21;1;23;0
WireConnection;161;0;160;0
WireConnection;126;0;127;0
WireConnection;126;1;117;0
WireConnection;140;12;143;0
WireConnection;103;0;100;1
WireConnection;150;0;161;0
WireConnection;150;1;158;0
WireConnection;119;0;103;0
WireConnection;119;1;114;0
WireConnection;145;0;142;0
WireConnection;145;1;139;0
WireConnection;109;9;101;0
WireConnection;109;10;110;0
WireConnection;57;0;30;0
WireConnection;57;2;56;0
WireConnection;91;0;10;0
WireConnection;91;1;6;0
WireConnection;91;2;9;0
WireConnection;101;0;103;0
WireConnection;101;1;105;0
WireConnection;144;0;137;0
WireConnection;144;2;145;0
WireConnection;48;0;44;0
WireConnection;48;1;46;0
WireConnection;116;9;119;0
WireConnection;116;10;110;0
WireConnection;158;0;165;0
WireConnection;52;12;53;0
WireConnection;143;0;141;0
WireConnection;143;2;138;0
WireConnection;154;0;158;1
WireConnection;154;1;161;1
WireConnection;2;2;136;0
WireConnection;2;5;42;0
ASEEND*/
//CHKSM=A2B5B5C2F60C3DF8C5773B17E2B5225AD909E32F