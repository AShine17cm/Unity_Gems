using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace URP
{
    public static class BuiltinKeyword
    {
        public static readonly string UNITY_HDR_ON = "UNITY_HDR_ON";
        public static readonly string LIGHTPROBE_SH = "LIGHTPROBE_SH";

        public static readonly string REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR =
            "REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR";
    }

    public static class BuiltinAutoStrippedKeyword
    {
        public static readonly string DIRLIGHTMAP_COMBINED = "DIRLIGHTMAP_COMBINED";
        public static readonly string DYNAMICLIGHTMAP_ON = "DYNAMICLIGHTMAP_ON";

        public static readonly string FOG_LINEAR = "FOG_LINEAR";
        public static readonly string FOG_EXP = "FOG_EXP";
        public static readonly string FOG_EXP2 = "FOG_EXP2";

        public static readonly string INSTANCING_ON = "INSTANCING_ON";

        public static readonly string LIGHTMAP_ON = "LIGHTMAP_ON";
        public static readonly string LIGHTMAP_SHADOW_MIXING = "LIGHTMAP_SHADOW_MIXING";
        public static readonly string SHADOWS_SHADOWMASK = "SHADOWS_SHADOWMASK";
    }

    public static class LegacyKeyword
    {
        // Legacy
        public static readonly string MATERIAL_QUALITY_HIGH = "MATERIAL_QUALITY_HIGH";
        public static readonly string MATERIAL_QUALITY_MEDIUM = "MATERIAL_QUALITY_MEDIUM";
        public static readonly string MATERIAL_QUALITY_LOW = "MATERIAL_QUALITY_LOW";
        public static readonly string _SPECULAR_COLOR = "_SPECULAR_COLOR";

        public static readonly string _MOSS = "_MOSS";
        public static readonly string _VOFFSET = "_VOFFSET";
        public static readonly string _DEBUG = "_DEBUG";
        public static readonly string _SECONDARYLOBE = "_SECONDARYLOBE";
        public static readonly string _STRANDDIR_BITANGENT = "_STRANDDIR_BITANGENT";
    }

    public static class Keyword
    {
        public static readonly string _PAN = "_PAN";
        public static readonly string _ALPHATEST_ON = "_ALPHATEST_ON";
        public static readonly string _ALPHAPREMULTIPLY_ON = "_ALPHAPREMULTIPLY_ON";
        public static readonly string _ALPHAMODULATE_ON = "_ALPHAMODULATE_ON";
        public static readonly string _RECEIVE_SHADOWS_OFF = "_RECEIVE_SHADOWS_OFF";

        public static readonly string _NORMALMAP = "_NORMALMAP";
        public static readonly string _MATCAP = "_MATCAP";
        public static readonly string _EMISSION = "_EMISSION";
        public static readonly string _OPAQUETEX = "_OPAQUETEX";

        public static readonly string REQUIRE_DEPTH_TEXTURE = "REQUIRE_DEPTH_TEXTURE";
        public static readonly string _VCOLOR = "_VCOLOR";
        public static readonly string _VFACE = "_VFACE";

        public static readonly string _ADDOrBLEND = "_ADDOrBLEND";
        public static readonly string _TRIPLANAR = "_TRIPLANAR";

        public static readonly string _MASKMAP = "_MASKMAP";

        public static readonly string _PATTERNMAP = "_PATTERNMAP";

        public static readonly string _ENVIRONMENT = "_ENVIRONMENT";

        public static readonly string _ENVIRONMENTMAP = "_ENVIRONMENTMAP";

        public static readonly string _IRIDESCENCE_THICKNESSMAP = "_IRIDESCENCE_THICKNESSMAP";

        public static readonly string _ENABLEGRADIENT = "_HairGradient";

        public static readonly string _ENABLESKIN = "_ENABLESKIN";

        public static readonly string _FresnelOn = "_FresnelBlend_On";

        public static readonly string _COLOR_SOFTLIGHT = "_COLOR_SOFTLIGHT";

        public static readonly string _EnableShadowOffset = "_SHADOW_OFFSET";

        public static readonly string _COTTONWOOL = "_COTTONWOOL";
        public static readonly string _SCATTERING = "_SCATTERING";

        public static readonly string _NEED_POS_OS = "_NEED_POS_OS";
        public static readonly string _NEED_POS_WS = "_NEED_POS_WS";

        public static readonly string _READ_PROPS = "_READ_PROPS";

        public static readonly string _SPECULARHIGHLIGHTS_OFF = "_SPECULARHIGHLIGHTS_OFF";
        public static readonly string _ENVIRONMENTREFLECTIONS_OFF = "_ENVIRONMENTREFLECTIONS_OFF";

        //UniversalLit
        public static readonly string _ENABLE_LIT = "_ENABLE_LIT";
        public static readonly string _ENABLE_SKIN = "_ENABLE_SKIN";
        public static readonly string _ENABLE_HAIR = "_ENABLE_HAIR";
        public static List<string> LegacyKeywordList
        {
            get
            {
                return typeof(LegacyKeyword).GetFields(BindingFlags.Static |
                                                       BindingFlags.Public)
                                            .Where(f => f.FieldType == typeof(string))
                                            .Select(f => (string)f.GetValue(null))
                                            .ToList();
            }
        }

        public static List<string> CustomizedUserDefined
        {
            get
            {
                return typeof(Keyword).GetFields(BindingFlags.Static |
                                                 BindingFlags.Public)
                                      .Where(f => f.FieldType == typeof(string))
                                      .Select(f => (string)f.GetValue(null))
                                      .ToList();
            }
        }

        public static List<string> URPKeywordList()
        {
            var list = new List<string>();
            var ps = typeof(ShaderKeywordStrings).GetFields(BindingFlags.Static |
                                                            BindingFlags.Public)
                                                 .Where(f => f.FieldType == typeof(string));

            foreach (var propertyInfo in ps)
            {
                list.Add((string)propertyInfo.GetValue(null));
            }


            return list;
        }

        public static List<string> UserDefinedKeywordList()
        {
            var list = URPKeywordList();
            var ps = typeof(ShaderKeywordStrings).GetFields(BindingFlags.Static |
                                                            BindingFlags.Public)
                                                 .Where(f => f.FieldType == typeof(string)).ToList();

            foreach (var propertyInfo in ps)
            {
                list.Add((string)propertyInfo.GetValue(null));
            }

            return list;
        }
    }

    public static class Prop
    {
        public static readonly string _Material_Quality = "_Material_Quality";
        public static readonly string _Surface = "_Surface";
        public static readonly string _Blend = "_Blend";
        public static readonly string _SrcBlend = "_SrcBlend";
        public static readonly string _DstBlend = "_DstBlend";
        public static readonly string _ZWrite = "_ZWrite";
        public static readonly string _AlphaClip = "_AlphaClip";
        public static readonly string _Cull = "_Cull";
        public static readonly string _Cutoff = "_Cutoff";
        public static readonly string _ReceiveShadows = "_ReceiveShadows";
        public static readonly string _QueueOffset = "_QueueOffset";
        public static readonly string _MaterialMode = "_MaterialMode";

        public static readonly string enableStippleTransparency = "_EnableStippleTransparency";

        public static readonly string _EnableOpaqueTexture = "_EnableOpaqueTexture";

        public static readonly string _SpecularHighlights = "_SpecularHighlights";
        public static readonly string _EnvironmentReflections = "_EnvironmentReflections";
        public static readonly string _ReadProps = "_ReadProps";


        public static readonly string _ScaleProp = "_Scale";
        //public static readonly string _CurvatureScaleBias = "_CurvatureScaleBias";
        public static readonly string _ColorOverlayType = "_ColorOverlayType";

        public static readonly string _TranprantAlpha = "_TranprantAlpha";

        public static readonly string _BaseMap = "_BaseMap";
        public static readonly string _BumpMap = "_BumpMap";
        public static readonly string _NSMap = "_NSMap";
        public static readonly string _EmissionMap = "_EmissionMap";
        public static readonly string _MaskMap = "_MaskMap";
        public static readonly string _MatcapMap = "_MatcapMap";
        public static readonly string _Cubemap = "_Cubemap";
        public static readonly string _PannerTex = "_PannerTex";
        public static readonly string _DissloveTex = "_DissloveTex";
        public static readonly string _LayerTex = "_LayerTex";

     

        public static readonly string _EnableMaskMap = "_EnableMaskMap";
        public static readonly string _EnablePattern = "_EnablePattern";
        public static readonly string _EnableUVAnim = "_EnableUVAnim";

        //UniversalLit
        public static readonly string _EnableLit = "_EnableLit";
        public static readonly string _EnableSkinProp = "_EnableSkinToggle";
        public static readonly string _EnableHair = "_EnableHair";
        public static readonly string _ShaderType = "_ShaderType";

        //stencil
        public static readonly string _StencilID = "_StencilID";
        public static readonly string _StencilCompMode = "_StencilCompMode";

        public static readonly string _FurLength = "_FurLength";
        public static readonly string _MaskSmooth = "_MaskSmooth";
        public static readonly string _NoiseScale = "_NoiseScale";

        //public static readonly string _CutoffStart = "_CutoffStart";
        public static readonly string _CutoffEnd = "_CutoffEnd";
        public static readonly string _EdgeFade = "_EdgeFade";
        public static readonly string _Gravity = "_Gravity"; 
        public static readonly string _GravityStrength = "_GravityStrength";
        public static readonly string _FabricScatterColor = "_FabricScatterColor";
        public static readonly string _FabricScatterScale = "_FabricScatterScale";
        public static readonly string _ShadowColor = "_ShadowColor";
        public static readonly string _ShadowAO = "_ShadowAO";

        public static readonly string _IridescenceThickness = "_IridescenceThickness";
        public static readonly string _IridescenceThicknessMap = "_IridescenceThicknessMap";
        public static readonly string _IridescenceThicknessRemap = "_IridescenceThicknessRemap";
        public static readonly string _IridescneceEta2 = "_IridescneceEta2";
        public static readonly string _IridescneceEta3 = "_IridescneceEta3";
        public static readonly string _IridescneceKappa3 = "_IridescneceKappa3";



        public static readonly string _PatternMap = "_PatternMap";
        public static readonly string _Contrast = "_Contrast";
        public static readonly string _EnableTriplanar = "_EnableTriplanar";

        public static readonly string _TextureSize = "_TextureSize";
        public static readonly string _LUTMap = "_LUTMap";
        public static readonly string _lightPower = "_lightPower";
        public static readonly string _addSkinColor = "_addSkinColor";
        public static readonly string _EnableSkin = "_EnableSkin";


        public static readonly string _EnableNormal = "_EnableNormal";
        public static readonly string _EmissionEnabled = "_EmissionEnabled";
        public static readonly string _EnableMoss = "_EnableMoss";
        public static readonly string _EnableIntersection = "_EnableIntersection";
        public static readonly string _ValueRemap = "_ValueRemap";

      
        public static readonly string _EnableEnvironmentMap = "_EnableEnvironmentMap";
        public static readonly string _EnvironmentMap = "_EnvironmentMap";
        public static readonly string _EnvExposure = "_EnvExposure";
        public static readonly string _PunctualLightSpecularExposure = "_PunctualLightSpecularExposure";
        public static readonly string _EnvironmentColor = "_EnvironmentColor";

        public static readonly string _Frenesl = "_Fresnel";

        public static readonly string _EnableGradient = "_EnableGradient";
        public static readonly string _GradientMap = "_GradientMap";
        public static readonly string _Intensity = "_Intensity";
        public static readonly string _Fill = "_Fill";
      //  public static readonly string _GradientMaskMap = "_GradientMaskMap";
        public static readonly string _Gradient_U_Speed = "_Gradient_U_Speed";
        public static readonly string _Gradient_V_Speed = "_Gradient_V_Speed";
        public static readonly string _GradientColor = "_GradientColor";



        public static readonly string _MossMap = "_MossMap";
        public static readonly string _MossScale = "_MossScale";
        public static readonly string _MossSmoothness = "_MossSmoothness";
        public static readonly string _EnableVertexOffset = "_EnableVertexOffset";
        public static readonly string _VertexOffset = "_VertexOffset";

        public static readonly string _HeightBlend = "_HeightBlend";
        public static readonly string _BlendDistance = "_BlendDistance";
        public static readonly string _BlendAngle = "_BlendAngle";

        public static readonly string _EnableSSS = "_EnableSSS";
        public static readonly string _SubsurfaceColor = "_SubsurfaceColor";

        public static readonly string _Anisotropy = "_Anisotropy";
        public static readonly string _UseCottonWool = "_UseCottonWool";
        public static readonly string _SheenColor = "_SheenColor";

        public static readonly string _UseScattering = "_UseScattering";
        public static readonly string _TranslucencyPower = "_TranslucencyPower";
        public static readonly string _ShadowStrength = "_ShadowStrength";
        public static readonly string _Distortion = "_Distortion";

        public static readonly string _EnableShadowOffset = "_EnableShadowOffset";

        public static readonly string _ShadowOffset = "_ShadowOffset";

        public static readonly string _RefractAmount = "_RefractAmount";
        public static readonly string _EnablePivotAO = "_EnablePivotAO";
        public static readonly string _Params = "_Params";


        public static readonly string _Debug = "_Debug";
        public static readonly string _DebugToggle = "_DebugToggle";
        public static readonly string _EmissionColor = "_EmissionColor";

        // Editor Only
        public static readonly string _EmissionPower = "_EmissionPower";
        public static readonly string _PanOrPulsateEmission = "_PanOrPulsateEmission";
        public static readonly string _PanOrPulsate = "_PanOrPulsate";
        public static readonly string _RimColor = "_RimColor";
        public static readonly string _RimPower = "_RimPower";
        public static readonly string _RimIntensity = "_RimIntensity";
        public static readonly string _RimWidth = "_RimWidth";
        public static readonly string _RimSmoothness = "_RimSmoothness";
        public static readonly string _EnableRimOn = "_EnableRim";

        public static readonly string _CastShadow = "_CastShadow";

        public static readonly string _SpecColor = "_SpecColor";
        public static readonly string _Smoothness = "_Smoothness";
        public static readonly string _BaseColor = "_BaseColor";
        public static readonly string _SecondaryColor = "_SecondaryColor";

        public static readonly string _ColorMode = "_ColorMode";
        public static readonly string _ChangeColor = "_ChangeColor";
        public static readonly string _SoftColor = "_SoftColor";
        public static readonly string _Saturation = "_SaturationValue";

        public static readonly string _RenderSide = "_RenderSide";


        public static readonly string _StrandDir = "_StrandDir";
        public static readonly string _SpecularShift = "_SpecularShift";
        public static readonly string _SpecularTint = "_SpecularTint";
        public static readonly string _SpecularExponent = "_SpecularExponent";
        public static readonly string _SecondaryLobe = "_SecondaryLobe";
        public static readonly string _SecondarySpecularShift = "_SecondarySpecularShift";
        public static readonly string _SecondarySpecularTint = "_SecondarySpecularTint";
        public static readonly string _SecondarySpecularExponent = "_SecondarySpecularExponent";

        public static readonly string _RimTransmissionIntensity = "_RimTransmissionIntensity";
        public static readonly string _AmbientReflection = "_AmbientReflection";
        public static readonly string _BaseMapAlphaAsSmoothness = "_BaseMapAlphaAsSmoothness";

        public static readonly string _Range = "_Range";
        public static readonly string _Speed = "_Speed";
        public static readonly string _Amplitude = "_Amplitude";
        public static readonly string _CameraDistance = "_CameraDistance";

        public static readonly string _Splat0_Smoothness = "_Splat0_Smoothness";
        public static readonly string _Splat1_Smoothness = "_Splat1_Smoothness";
        public static readonly string _Splat2_Smoothness = "_Splat2_Smoothness";
        public static readonly string _Splat3_Smoothness = "_Splat3_Smoothness";

        public static readonly string _Splat0_S = "_Splat0_S";
        public static readonly string _Splat1_S = "_Splat1_S";
        public static readonly string _Splat2_S = "_Splat2_S";
        public static readonly string _Splat3_S = "_Splat3_S";

        public static readonly string _Splat0_Normal = "_Splat0_Normal";
        public static readonly string _Splat1_Normal = "_Splat1_Normal";
        public static readonly string _Splat2_Normal = "_Splat2_Normal";
        public static readonly string _Splat3_Normal = "_Splat3_Normal";
    }

    public static class Tag
    {
        public static readonly string RenderType = "RenderType";
        public static readonly string TransparentCutout = "TransparentCutout";
        public static readonly string Opaque = "Opaque";
        public static readonly string Transparent = "Transparent";
    }

    public static class Pass
    {
        public static readonly string ShadowCaster = "ShadowCaster";
    }

    public static class LegacyProp
    {
        public static readonly string _MainTex = "_MainTex";
        public static readonly string _TintColor = "_TintColor";
        public static readonly string _MaskMap = "_MaskMap";
        public static readonly string _Shininess = "_Shininess";
        public static readonly string _NMRTex = "_NMRTex";
        public static readonly string _Gloss = "_Gloss";
        public static readonly string _AnisoOffset = "_AnisoOffset";
        public static readonly string _BumpMap = "_BumpMap";
        public static readonly string _SkinColor = "_SkinColor";
        public static readonly string _Maskcolor = "_Maskcolor";
        public static readonly string _Maskcolorpower = "_Maskcolorpower";
        public static readonly string _Maskpanner = "_Maskpanner";
        public static readonly string _PanEmission = "_PanEmission";
        public static readonly string _Pan = "_Pan";
        public static readonly string _SpecularColor = "_SpecularColor";

        public static readonly string _ShininessL0 = "_ShininessL0";
        public static readonly string _ShininessL1 = "_ShininessL1";
        public static readonly string _ShininessL2 = "_ShininessL2";
        public static readonly string _ShininessL3 = "_ShininessL3";

        public static readonly string _BumpSplat0 = "_BumpSplat0";

        public static readonly string _Splat0 = "_Splat0";
        public static readonly string _Splat1 = "_Splat1";
        public static readonly string _Splat2 = "_Splat2";
        public static readonly string _Splat3 = "_Splat3";
    }

    public static class LegacyShader
    {
        public static readonly string PBR_M4 = "Custom/PBR/PBR_M4";
        public static readonly string PBR_M4_1 = "Custom/PBR/PBR_M41";
        public static readonly string AnisotropicBumped = "Custom/Anisotropic Bumped Specular";
        public static readonly string pbr_unity_2 = "pbr/unity.2";
        public static readonly string pbr_unity_2fx = "pbr/unity.2.fx";
        public static readonly string CustomBumpedSpecularNoSpot = "Custom/Bumped Specular No Spot";
        public static readonly string CustomBumpedSpecular = "Custom/Bumped Specular";
        public static readonly string CustomBumpedDiffuse = "Custom/Bumped Diffuse";
        public static readonly string CustomColorBumpedSpecular = "Custom/Colord Bumped Specular";
        public static readonly string CustomBumpedDiffuseCutoff = "Custom/Bumped Diffuse CutOff";
        public static readonly string CustomBumpedSpecularCutoff = "Custom/Bumped Specular CutOff";
        public static readonly string CustomSpecLit = "Custom/Specular_lit";
        public static readonly string CustomSpec = "Custom/ Specular";
        public static readonly string CustomVertexLit = "Custom/VertexLit";
        public static readonly string CustomDiffuse = "Custom/Diffuse";
        public static readonly string MobileDiffuse = "Mobile/Diffuse";
        public static readonly string UnlitTexture = "Unlit/Texture";
        public static readonly string T4MBumpSpec = "T4MShaders/ShaderModel3/BumpSpec/T4M 4 Textures Bump Spec";
        public static readonly string GuanMu_AlphaTest = "SC/GuanMu_AlphaTest";
        public static readonly string Tree_AlphaTest = "SC/Tree_AlphaTest";
        public static readonly string Tree_LOD1 = "SC/Tree_LOD1";
        public static readonly string Standard = "Standard";
        public static readonly string CustomDiffuseCutOff = "Custom/Diffuse CutOff";
        public const string ParticlesAdditive = "Legacy Shaders/Particles/Additive";
        public const string ParticlesAlphaBlended = "Legacy Shaders/Particles/Anim Alpha Blended";
    }

    public static class URPShader
    {
        public static readonly string Lit = "_URP/Lit";
        public static readonly string Lit_New = "_URP/Lit_New";
        public static readonly string Lit_Alpha_New = "_URP/Lit.Alpha_New";
        public static readonly string Hair = "_URP/Hair";
        public static readonly string Skin = "_URP/Skin";
        public static readonly string Cloth = "_URP/Cloth";
        public static readonly string SimpleLit = "_URP/SimpleLit";
        public static readonly string VertexLit = "_URP/VertexLit";
        public static readonly string Unlit = "_URP/UnLit";
        public static readonly string TerrainMeshBase_4 = "_URP/TerrainMeshBase/4 Textures";
        public static readonly string TerrainMeshBase_3 = "_URP/TerrainMeshBase/3 Textures";
        public static readonly string Foliage_Tree = "_URP/Foliage/Tree.VertexLit";
        public static readonly string PartcileAdditive = "_URP/VFX/Particles Additive";
        public static readonly string PartcileAlpahBlended = "_URP/VFX/Particles Alpha Blended";
    }
}