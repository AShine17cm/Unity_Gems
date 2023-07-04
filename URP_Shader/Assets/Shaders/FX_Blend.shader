// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Yo/Blend"
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
		_Main_U_Speed("Main_U_Speed", Float) = 0
		_Main_V_Speed("Main_V_Speed", Float) = 0
		_Main_U_Offset("Main_U_Offset", Float) = 0
		_Main_V_Offset("Main_V_Offset", Float) = 0
		_Mask("Mask", 2D) = "white" {}
		_MaskIntensity("MaskIntensity", Float) = 1.76
		_MaskRota("MaskRota", Float) = 0
		[Toggle]_MaskPolar("MaskPolar", Float) = 0
		_Mask_U_Speed("Mask_U_Speed", Float) = 0
		_Mask_V_Speed("Mask_V_Speed", Float) = 0
		_PannerTex("PannerTex", 2D) = "white" {}
		_PannerRota("PannerRota", Float) = 0
		_PannerIntensity("PannerIntensity", Float) = 0
		[Toggle]_PannerPolar("PannerPolar", Float) = 0
		_Panner_U_Speed("Panner_U_Speed", Float) = 0
		_Panner_V_Speed("Panner_V_Speed", Float) = 0
		_DissloveTex("DissloveTex", 2D) = "white" {}
		_DissRota("DissRota", Float) = 0
		[Toggle]_DissPolar("DissPolar", Float) = 0
		_Diss_U_Speed("Diss_U_Speed", Float) = 0
		_Diss_V_Speed("Diss_V_Speed", Float) = 0
		_Hardness("Hardness", Range( 0 , 1)) = 0
		_Edgewidth("Edgewidth", Range( 0 , 1)) = 0
		[HDR]_EdgeColor("EdgeColor", Color) = (1,0,0,1)
		_DissloveIntensity("DissloveIntensity", Range( 0 , 1)) = 0.02629435
		[Toggle]_Fresnel("Fresnel", Float) = 0
		[HDR]_FresnelColor("FresnelColor", Color) = (1,0,0,1)
		_FresnelWidth("FresnelWidth", Float) = 1
		_FresnelIntensity("FresnelIntensity", Float) = 1
		[Enum(Particle,0,Model,1)]_Mode("Mode", Float) = 0
       //[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestCompMode("ZTestCompMode",Float) = 4
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
			
			Blend SrcAlpha OneMinusSrcAlpha , One OneMinusSrcAlpha
			ZWrite Off
			//ZTest[_ZTestCompMode]
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

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
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
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _EdgeColor;
			half4 _Color;
			float4 _Mask_ST;
			float4 _DissloveTex_ST;
			float4 _MainTex_ST;
			float4 _PannerTex_ST;
			half4 _FresnelColor;
			half _Fresnel;
			half _DissPolar;
			half _DissRota;
			half _Edgewidth;
			half _FresnelIntensity;
			half _Diss_V_Speed;
			half _FresnelWidth;
			half _Mask_U_Speed;
			half _Mask_V_Speed;
			half _MaskPolar;
			half _Hardness;
			half _Diss_U_Speed;
			half _PannerIntensity;
			half _MaskRota;
			half _DissloveIntensity;
			half _Main_V_Offset;
			half _Main_U_Offset;
			half _PannerRota;
			half _PannerPolar;
			half _Panner_V_Speed;
			half _Panner_U_Speed;
			half _Extrusion;
			half _MainRota;
			half _MainPolar;
			half _Main_V_Speed;
			half _Main_U_Speed;
			float _Mode;
			half _MaskIntensity;
			float _TessPhongStrength;
			float _TessValue;
			float _TessMin;
			float _TessMax;
			float _TessEdgeLength;
			float _TessMaxDisp;
			CBUFFER_END
			sampler2D _MainTex;
			sampler2D _PannerTex;
			sampler2D _DissloveTex;
			sampler2D _Mask;


						
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord5.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
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
				float2 appendResult33 = (float2(_Main_U_Speed , _Main_V_Speed));
				float2 uv0_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float cos29 = cos( _MainRota );
				float sin29 = sin( _MainRota );
				float2 rotator29 = mul( uv0_MainTex - float2( 0.5,0.5 ) , float2x2( cos29 , -sin29 , sin29 , cos29 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g43 = (rotator29*2.0 + -1.0);
				float2 break3_g43 = temp_output_2_0_g43;
				float2 appendResult8_g43 = (float2(pow( length( temp_output_2_0_g43 ) , _Extrusion ) , ( ( atan2( break3_g43.y , break3_g43.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner35 = ( 1.0 * _Time.y * appendResult33 + (( _MainPolar )?( appendResult8_g43 ):( rotator29 )));
				float2 appendResult71 = (float2(_Panner_U_Speed , _Panner_V_Speed));
				float2 uv0_PannerTex = IN.ase_texcoord3.xy * _PannerTex_ST.xy + _PannerTex_ST.zw;
				float cos67 = cos( _PannerRota );
				float sin67 = sin( _PannerRota );
				float2 rotator67 = mul( uv0_PannerTex - float2( 0.5,0.5 ) , float2x2( cos67 , -sin67 , sin67 , cos67 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g40 = (rotator67*2.0 + -1.0);
				float2 break3_g40 = temp_output_2_0_g40;
				float2 appendResult8_g40 = (float2(pow( length( temp_output_2_0_g40 ) , _Extrusion ) , ( ( atan2( break3_g40.y , break3_g40.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner73 = ( 1.0 * _Time.y * appendResult71 + (( _PannerPolar )?( appendResult8_g40 ):( rotator67 )));
				float4 uv1112 = IN.ase_texcoord4;
				uv1112.xy = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult113 = (float4(_Main_U_Offset , _Main_V_Offset , _DissloveIntensity , _PannerIntensity));
				float4 lerpResult114 = lerp( uv1112 , appendResult113 , _Mode);
				float4 break115 = lerpResult114;
				float4 tex2DNode1 = tex2D( _MainTex, ( panner35 + ( tex2D( _PannerTex, panner73 ).r * break115.w ) ) );
				float2 appendResult91 = (float2(_Diss_U_Speed , _Diss_V_Speed));
				float2 uv0_DissloveTex = IN.ase_texcoord3.xy * _DissloveTex_ST.xy + _DissloveTex_ST.zw;
				float cos84 = cos( _DissRota );
				float sin84 = sin( _DissRota );
				float2 rotator84 = mul( uv0_DissloveTex - float2( 0.5,0.5 ) , float2x2( cos84 , -sin84 , sin84 , cos84 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g41 = (rotator84*2.0 + -1.0);
				float2 break3_g41 = temp_output_2_0_g41;
				float2 appendResult8_g41 = (float2(pow( length( temp_output_2_0_g41 ) , _Extrusion ) , ( ( atan2( break3_g41.y , break3_g41.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner95 = ( 1.0 * _Time.y * appendResult91 + (( _DissPolar )?( appendResult8_g41 ):( rotator84 )));
				float temp_output_100_0 = ( tex2D( _DissloveTex, panner95 ).r + 1.0 );
				float temp_output_93_0 = ( break115.z * ( 1.0 + _Edgewidth ) );
				half Hardness82 = _Hardness;
				float temp_output_90_0 = ( 1.0 - Hardness82 );
				float temp_output_10_0_g46 = _Hardness;
				float4 lerpResult109 = lerp( _EdgeColor , ( _Color * tex2DNode1 * IN.ase_color ) , saturate( ( ( ( temp_output_100_0 - ( temp_output_93_0 * ( 1.0 + temp_output_90_0 ) ) ) - temp_output_10_0_g46 ) / ( 1.0 - temp_output_10_0_g46 ) ) ));
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float fresnelNdotV116 = dot( ase_worldNormal, ase_worldViewDir );
				float fresnelNode116 = ( 0.0 + _FresnelIntensity * pow( abs(1.0 - fresnelNdotV116), _FresnelWidth ) );
				
				float temp_output_10_0_g45 = _Hardness;
				float2 appendResult59 = (float2(_Mask_U_Speed , _Mask_V_Speed));
				float2 uv0_Mask = IN.ase_texcoord3.xy * _Mask_ST.xy + _Mask_ST.zw;
				float cos54 = cos( _MaskRota );
				float sin54 = sin( _MaskRota );
				float2 rotator54 = mul( uv0_Mask - float2( 0.5,0.5 ) , float2x2( cos54 , -sin54 , sin54 , cos54 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g44 = (rotator54*2.0 + -1.0);
				float2 break3_g44 = temp_output_2_0_g44;
				float2 appendResult8_g44 = (float2(pow( length( temp_output_2_0_g44 ) , _Extrusion ) , ( ( atan2( break3_g44.y , break3_g44.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner60 = ( 1.0 * _Time.y * appendResult59 + (( _MaskPolar )?( appendResult8_g44 ):( rotator54 )));
				float4 tex2DNode61 = tex2D( _Mask, panner60 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = (( _Fresnel )?( ( ( _FresnelColor * fresnelNode116 ) + lerpResult109 ) ):( lerpResult109 )).rgb;
				float Alpha = saturate( ( saturate( ( ( ( temp_output_100_0 - ( ( temp_output_93_0 - _Edgewidth ) * ( 1.0 + temp_output_90_0 ) ) ) - temp_output_10_0_g45 ) / ( 1.0 - temp_output_10_0_g45 ) ) ) * _Color.a * tex2DNode1.a * IN.ase_color.a * ( tex2DNode61.r * tex2DNode61.a * _MaskIntensity ) ) );
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
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _EdgeColor;
			half4 _Color;
			float4 _Mask_ST;
			float4 _DissloveTex_ST;
			float4 _MainTex_ST;
			float4 _PannerTex_ST;
			half4 _FresnelColor;
			half _Fresnel;
			half _DissPolar;
			half _DissRota;
			half _Edgewidth;
			half _FresnelIntensity;
			half _Diss_V_Speed;
			half _FresnelWidth;
			half _Mask_U_Speed;
			half _Mask_V_Speed;
			half _MaskPolar;
			half _Hardness;
			half _Diss_U_Speed;
			half _PannerIntensity;
			half _MaskRota;
			half _DissloveIntensity;
			half _Main_V_Offset;
			half _Main_U_Offset;
			half _PannerRota;
			half _PannerPolar;
			half _Panner_V_Speed;
			half _Panner_U_Speed;
			half _Extrusion;
			half _MainRota;
			half _MainPolar;
			half _Main_V_Speed;
			half _Main_U_Speed;
			float _Mode;
			half _MaskIntensity;
			float _TessPhongStrength;
			float _TessValue;
			float _TessMin;
			float _TessMax;
			float _TessEdgeLength;
			float _TessMaxDisp;
			CBUFFER_END
			sampler2D _DissloveTex;
			sampler2D _MainTex;
			sampler2D _PannerTex;
			sampler2D _Mask;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_texcoord3 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
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

				float2 appendResult91 = (float2(_Diss_U_Speed , _Diss_V_Speed));
				float2 uv0_DissloveTex = IN.ase_texcoord2.xy * _DissloveTex_ST.xy + _DissloveTex_ST.zw;
				float cos84 = cos( _DissRota );
				float sin84 = sin( _DissRota );
				float2 rotator84 = mul( uv0_DissloveTex - float2( 0.5,0.5 ) , float2x2( cos84 , -sin84 , sin84 , cos84 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g41 = (rotator84*2.0 + -1.0);
				float2 break3_g41 = temp_output_2_0_g41;
				float2 appendResult8_g41 = (float2(pow( length( temp_output_2_0_g41 ) , _Extrusion ) , ( ( atan2( break3_g41.y , break3_g41.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner95 = ( 1.0 * _Time.y * appendResult91 + (( _DissPolar )?( appendResult8_g41 ):( rotator84 )));
				float temp_output_100_0 = ( tex2D( _DissloveTex, panner95 ).r + 1.0 );
				float4 uv1112 = IN.ase_texcoord3;
				uv1112.xy = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult113 = (float4(_Main_U_Offset , _Main_V_Offset , _DissloveIntensity , _PannerIntensity));
				float4 lerpResult114 = lerp( uv1112 , appendResult113 , _Mode);
				float4 break115 = lerpResult114;
				float temp_output_93_0 = ( break115.z * ( 1.0 + _Edgewidth ) );
				half Hardness82 = _Hardness;
				float temp_output_90_0 = ( 1.0 - Hardness82 );
				float temp_output_10_0_g45 = _Hardness;
				float2 appendResult33 = (float2(_Main_U_Speed , _Main_V_Speed));
				float2 uv0_MainTex = IN.ase_texcoord2.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float cos29 = cos( _MainRota );
				float sin29 = sin( _MainRota );
				float2 rotator29 = mul( uv0_MainTex - float2( 0.5,0.5 ) , float2x2( cos29 , -sin29 , sin29 , cos29 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g43 = (rotator29*2.0 + -1.0);
				float2 break3_g43 = temp_output_2_0_g43;
				float2 appendResult8_g43 = (float2(pow( length( temp_output_2_0_g43 ) , _Extrusion ) , ( ( atan2( break3_g43.y , break3_g43.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner35 = ( 1.0 * _Time.y * appendResult33 + (( _MainPolar )?( appendResult8_g43 ):( rotator29 )));
				float2 appendResult71 = (float2(_Panner_U_Speed , _Panner_V_Speed));
				float2 uv0_PannerTex = IN.ase_texcoord2.xy * _PannerTex_ST.xy + _PannerTex_ST.zw;
				float cos67 = cos( _PannerRota );
				float sin67 = sin( _PannerRota );
				float2 rotator67 = mul( uv0_PannerTex - float2( 0.5,0.5 ) , float2x2( cos67 , -sin67 , sin67 , cos67 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g40 = (rotator67*2.0 + -1.0);
				float2 break3_g40 = temp_output_2_0_g40;
				float2 appendResult8_g40 = (float2(pow( length( temp_output_2_0_g40 ) , _Extrusion ) , ( ( atan2( break3_g40.y , break3_g40.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner73 = ( 1.0 * _Time.y * appendResult71 + (( _PannerPolar )?( appendResult8_g40 ):( rotator67 )));
				float4 tex2DNode1 = tex2D( _MainTex, ( panner35 + ( tex2D( _PannerTex, panner73 ).r * break115.w ) ) );
				float2 appendResult59 = (float2(_Mask_U_Speed , _Mask_V_Speed));
				float2 uv0_Mask = IN.ase_texcoord2.xy * _Mask_ST.xy + _Mask_ST.zw;
				float cos54 = cos( _MaskRota );
				float sin54 = sin( _MaskRota );
				float2 rotator54 = mul( uv0_Mask - float2( 0.5,0.5 ) , float2x2( cos54 , -sin54 , sin54 , cos54 )) + float2( 0.5,0.5 );
				float2 temp_output_2_0_g44 = (rotator54*2.0 + -1.0);
				float2 break3_g44 = temp_output_2_0_g44;
				float2 appendResult8_g44 = (float2(pow( length( temp_output_2_0_g44 ) , _Extrusion ) , ( ( atan2( break3_g44.y , break3_g44.x ) / ( 2.0 * PI ) ) + 0.5 )));
				float2 panner60 = ( 1.0 * _Time.y * appendResult59 + (( _MaskPolar )?( appendResult8_g44 ):( rotator54 )));
				float4 tex2DNode61 = tex2D( _Mask, panner60 );
				
				float Alpha = saturate( ( saturate( ( ( ( temp_output_100_0 - ( ( temp_output_93_0 - _Edgewidth ) * ( 1.0 + temp_output_90_0 ) ) ) - temp_output_10_0_g45 ) / ( 1.0 - temp_output_10_0_g45 ) ) ) * _Color.a * tex2DNode1.a * IN.ase_color.a * ( tex2DNode61.r * tex2DNode61.a * _MaskIntensity ) ) );
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
-1920;31;1920;965;2106.359;2455.418;3.312358;True;False
Node;AmplifyShaderEditor.RangedFloatNode;37;-4188.797,-249.8296;Half;False;Property;_Main_V_Offset;Main_V_Offset;9;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;-4134.524,-28.26178;Half;False;Property;_PannerIntensity;PannerIntensity;18;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;110;-4223.354,-146.5782;Half;False;Property;_DissloveIntensity;DissloveIntensity;30;0;Create;True;0;0;False;0;False;0.02629435;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-4175.998,-337.5295;Half;False;Property;_Main_U_Offset;Main_U_Offset;8;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-2453.646,542.7347;Half;False;Property;_PannerRota;PannerRota;17;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;81;-2914.634,-851.5659;Half;False;Property;_DissRota;DissRota;23;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;80;-2988.682,-1017.422;Inherit;False;0;98;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;65;-2522.492,379.3486;Inherit;False;0;74;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;79;-673.8732,-696.698;Half;False;Property;_Hardness;Hardness;27;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;111;-3882.711,-67.51939;Inherit;False;Property;_Mode;Mode;35;1;[Enum];Create;True;2;Particle;0;Model;1;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;113;-3899.47,-305.744;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RotatorNode;67;-2248.71,421.3802;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;84;-2648.164,-1012.836;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;112;-3962.545,-494.4321;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;69;-1753.747,728.1595;Half;False;Property;_Panner_V_Speed;Panner_V_Speed;21;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;114;-3574.871,-390.8112;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-1968.8,-560.5448;Half;False;Property;_Edgewidth;Edgewidth;28;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;-2292.8,-846.3499;Half;False;Property;_Diss_U_Speed;Diss_U_Speed;25;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;-2297.665,-756.1169;Half;False;Property;_Diss_V_Speed;Diss_V_Speed;26;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;-2029.117,1264.269;Half;False;Property;_MaskRota;MaskRota;12;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;-355.3613,-693.662;Half;False;Hardness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;52;-2098.207,1093.783;Inherit;False;0;61;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;70;-1972.708,355.0858;Inherit;False;Polat Coordiates;0;;40;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;85;-2408.164,-1060.836;Inherit;False;Polat Coordiates;0;;41;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-1753.748,642.3596;Half;False;Property;_Panner_U_Speed;Panner_U_Speed;20;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;28;-1926.174,166.8012;Half;False;Property;_MainRota;MainRota;4;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;27;-2065.607,-3.159958;Inherit;False;0;1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;89;-1677.349,-461.4253;Inherit;False;82;Hardness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;115;-3377.972,-389.9891;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ToggleSwitchNode;72;-1622.372,419.7171;Half;True;Property;_PannerPolar;PannerPolar;19;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;92;-2072.163,-1023.836;Half;True;Property;_DissPolar;DissPolar;24;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;91;-2058.449,-786.2148;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;86;-1629.49,-624.718;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;29;-1725.088,1.425743;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;71;-1535.348,681.3595;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;54;-1824.178,1142.914;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;95;-1735.734,-950.8758;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-1458.49,-781.7179;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-1455.378,1414.609;Half;False;Property;_Mask_V_Speed;Mask_V_Speed;15;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;32;-1369.724,167.9119;Half;False;Property;_Main_U_Speed;Main_U_Speed;6;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;30;-1485.088,-46.57426;Inherit;False;Polat Coordiates;0;;43;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;73;-1304.159,504.8138;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-1374.589,258.1444;Half;False;Property;_Main_V_Speed;Main_V_Speed;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-1455.379,1328.809;Half;False;Property;_Mask_U_Speed;Mask_U_Speed;14;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;90;-1498.86,-455.4613;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;57;-1584.179,1076.62;Inherit;False;Polat Coordiates;0;;44;b2af5a165ccd34a4c8dc688bc9935107;0;1;12;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;34;-1133.088,1.425743;Half;True;Property;_MainPolar;MainPolar;5;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;96;-1273.84,-581.499;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;98;-1292.482,-981.8158;Inherit;True;Property;_DissloveTex;DissloveTex;22;0;Create;True;0;0;False;0;False;-1;097128b85d624d749838b48850d0972d;097128b85d624d749838b48850d0972d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;94;-1265.173,-414.0764;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-1135.374,228.0463;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;58;-1274.832,1136.128;Half;True;Property;_MaskPolar;MaskPolar;13;0;Create;True;0;0;False;0;False;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;59;-1236.978,1367.809;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;74;-1083.678,452.47;Inherit;True;Property;_PannerTex;PannerTex;16;0;Create;True;0;0;False;0;False;-1;1310c389b00742944a196851ef347845;1310c389b00742944a196851ef347845;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-1111.772,-485.6763;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;60;-970.4764,1184.755;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;100;-896.9028,-951.5659;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-746.0078,532.1152;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;35;-786.4085,4.083223;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;101;-649.8146,-543.7803;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;61;-738.0477,1155.23;Inherit;True;Property;_Mask;Mask;10;0;Create;True;0;0;False;0;False;-1;1310c389b00742944a196851ef347845;8c4a7fca2884fab419769ccc0355c0c1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;62;-616.85,1391.663;Half;False;Property;_MaskIntensity;MaskIntensity;11;0;Create;True;0;0;False;0;False;1.76;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-553.6747,204.525;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;1;-385,-31.5;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;False;0;False;-1;84508b93f15f2b64386ec07486afc7a3;84508b93f15f2b64386ec07486afc7a3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-270.8924,1184.755;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;102;-339.7851,-536.9122;Inherit;True;SmoothStep;-1;;45;1aab39c3f78b8e24a8943d8e8e34fbc4;0;3;9;FLOAT;0;False;10;FLOAT;0;False;11;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;38;-320.6436,-237.1809;Half;False;Property;_Color;Color;2;1;[HDR];Create;True;0;0;False;0;False;1,1,1,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;40;-259.6436,162.8191;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;180.8256,137.8191;Inherit;False;5;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;26;-2287.617,36.91641;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;126;924.5778,-531.9431;Half;False;Property;_Fresnel;Fresnel;31;0;Create;True;0;0;False;0;False;0;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-1012.4,-1293.622;Half;False;Property;_FresnelWidth;FresnelWidth;33;0;Create;True;0;0;False;0;False;1;3.59;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;39;6.356445,-216.1809;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;64;362.5311,116.8331;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;125;726.0061,-784.2745;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;105;-635.903,-947.5659;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;106;-307.3754,-1143.222;Half;False;Property;_EdgeColor;EdgeColor;29;1;[HDR];Create;True;0;0;False;0;False;1,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FresnelNode;116;-699.9158,-1424.886;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-1121.86,-782.4619;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;124;-300.6088,-1439.757;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;109;245.8776,-756.957;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;117;-1026.373,-1701.649;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;25;-2439.946,119.2218;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-1031.414,-1391.625;Half;False;Property;_FresnelIntensity;FresnelIntensity;34;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-2443.039,-60.84106;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;108;-341.8727,-946.6978;Inherit;True;SmoothStep;-1;;46;1aab39c3f78b8e24a8943d8e8e34fbc4;0;3;9;FLOAT;0;False;10;FLOAT;0;False;11;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;119;-1009.376,-1551.646;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;123;-621.3878,-1624.385;Half;False;Property;_FresnelColor;FresnelColor;32;1;[HDR];Create;True;0;0;False;0;False;1,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;22;-3036.602,2.61941;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;23;-2792.499,3.170313;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;107;-1271.26,-702.8621;Inherit;False;2;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;True;2;False;-1;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;1379.907,-221.9358;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Yo/Blend;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;7;False;False;False;True;2;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;0;True;1;5;False;-1;10;False;-1;1;1;False;-1;10;False;-1;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;21;Surface;1;  Blend;0;Two Sided;1;Cast Shadows;0;Receive Shadows;0;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;Meta Pass;0;DOTS Instancing;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;False;True;False;False;;0
WireConnection;113;0;36;0
WireConnection;113;1;37;0
WireConnection;113;2;110;0
WireConnection;113;3;78;0
WireConnection;67;0;65;0
WireConnection;67;2;66;0
WireConnection;84;0;80;0
WireConnection;84;2;81;0
WireConnection;114;0;112;0
WireConnection;114;1;113;0
WireConnection;114;2;111;0
WireConnection;82;0;79;0
WireConnection;70;12;67;0
WireConnection;85;12;84;0
WireConnection;27;1;26;0
WireConnection;115;0;114;0
WireConnection;72;0;67;0
WireConnection;72;1;70;0
WireConnection;92;0;84;0
WireConnection;92;1;85;0
WireConnection;91;0;88;0
WireConnection;91;1;87;0
WireConnection;86;1;83;0
WireConnection;29;0;27;0
WireConnection;29;2;28;0
WireConnection;71;0;68;0
WireConnection;71;1;69;0
WireConnection;54;0;52;0
WireConnection;54;2;53;0
WireConnection;95;0;92;0
WireConnection;95;2;91;0
WireConnection;93;0;115;2
WireConnection;93;1;86;0
WireConnection;30;12;29;0
WireConnection;73;0;72;0
WireConnection;73;2;71;0
WireConnection;90;0;89;0
WireConnection;57;12;54;0
WireConnection;34;0;29;0
WireConnection;34;1;30;0
WireConnection;96;0;93;0
WireConnection;96;1;83;0
WireConnection;98;1;95;0
WireConnection;94;1;90;0
WireConnection;33;0;32;0
WireConnection;33;1;31;0
WireConnection;58;0;54;0
WireConnection;58;1;57;0
WireConnection;59;0;56;0
WireConnection;59;1;55;0
WireConnection;74;1;73;0
WireConnection;97;0;96;0
WireConnection;97;1;94;0
WireConnection;60;0;58;0
WireConnection;60;2;59;0
WireConnection;100;0;98;1
WireConnection;75;0;74;1
WireConnection;75;1;115;3
WireConnection;35;0;34;0
WireConnection;35;2;33;0
WireConnection;101;0;100;0
WireConnection;101;1;97;0
WireConnection;61;1;60;0
WireConnection;76;0;35;0
WireConnection;76;1;75;0
WireConnection;1;1;76;0
WireConnection;63;0;61;1
WireConnection;63;1;61;4
WireConnection;63;2;62;0
WireConnection;102;9;101;0
WireConnection;102;10;79;0
WireConnection;41;0;102;0
WireConnection;41;1;38;4
WireConnection;41;2;1;4
WireConnection;41;3;40;4
WireConnection;41;4;63;0
WireConnection;26;0;24;0
WireConnection;26;1;25;0
WireConnection;126;0;109;0
WireConnection;126;1;125;0
WireConnection;39;0;38;0
WireConnection;39;1;1;0
WireConnection;39;2;40;0
WireConnection;64;0;41;0
WireConnection;125;0;124;0
WireConnection;125;1;109;0
WireConnection;105;0;100;0
WireConnection;105;1;103;0
WireConnection;116;0;117;0
WireConnection;116;4;119;0
WireConnection;116;2;120;0
WireConnection;116;3;121;0
WireConnection;103;0;93;0
WireConnection;103;1;107;0
WireConnection;124;0;123;0
WireConnection;124;1;116;0
WireConnection;109;0;106;0
WireConnection;109;1;39;0
WireConnection;109;2;108;0
WireConnection;25;0;23;1
WireConnection;25;1;115;1
WireConnection;24;0;115;0
WireConnection;24;1;23;0
WireConnection;108;9;105;0
WireConnection;108;10;79;0
WireConnection;23;0;22;0
WireConnection;107;1;90;0
WireConnection;3;2;126;0
WireConnection;3;3;64;0
ASEEND*/
//CHKSM=F79E1827DC83BE03D2E0C96597D1DFAE864E33D9