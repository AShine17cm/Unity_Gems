using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public abstract class BaseShaderGUI : ShaderGUI {
        #region EnumsAndClasses

        public enum SurfaceType {
            Opaque,
            Transparent
        }

        public enum BlendMode {
            Alpha, // Old school alpha-blending mode, fresnel does not affect amount of transparency
            Premultiply, // Physically plausible transparency mode, implemented as alpha pre-multiply
            Additive,
            Multiply
        }

        public enum RenderFace {
            Front = 2,
            Back = 1,
            Both = 0
        }

        public const int Editor_QUALITY = 400;
        public const int HIGH_QUALITY = 300;
        public const int MEDIUM_QUALITY = 250;
        public const int LOW_QUALITY = 200;

        protected class Styles {
            // Catergories
            public static readonly GUIContent SurfaceOptions =
                new GUIContent("Surface Options", "Controls how Universal RP renders the Material on a screen.");

            public static readonly GUIContent SurfaceInputs = new GUIContent("Surface Inputs",
                                                                             "These settings describe the look and feel of the surface itself.");

            public static readonly GUIContent AdvancedLabel = new GUIContent("Advanced",
                                                                             "These settings affect behind-the-scenes rendering and underlying calculations.");

            public static readonly GUIContent surfaceType = new GUIContent("Surface Type",
                                                                           "Select a surface type for your texture. Choose between Opaque or Transparent.");

            public static readonly GUIContent blendingMode = new GUIContent("Blending Mode",
                                                                            "Controls how the color of the Transparent surface blends with the Material color in the background.");

            public static readonly GUIContent cullingText = new GUIContent("Render Face",
                                                                           "Specifies which faces to cull from your geometry. Front culls front faces. Back culls backfaces. None means that both sides are rendered.");

            public static readonly GUIContent alphaClipText = new GUIContent("Alpha Clipping",
                                                                             "Makes your Material act like a Cutout shader. Use this to create a transparent effect with hard edges between opaque and transparent areas.");

            public static readonly GUIContent alphaClipThresholdText = new GUIContent("Threshold",
                                                                                      "Sets where the Alpha Clipping starts. The higher the value is, the brighter the  effect is when clipping starts.");

            public static readonly GUIContent receiveShadowText = new GUIContent("Receive Shadows",
                                                                                 "When enabled, other GameObjects can cast shadows onto this GameObject.");

            public static readonly GUIContent baseMap = new GUIContent("BA Map",
                                                                       "Albedo(RGB), Occlusion/Alpha(A) Specifies the base Material and/or Color of the surface. If you’ve selected Transparent or Alpha Clipping under Surface Options, your Material uses the Texture’s alpha channel to blend.");

            public static readonly GUIContent normalMapText =
                new GUIContent("NS Map", "Normal(RGB), Smoothness(A) Assigns a tangent-space normal map.");

            public static readonly GUIContent emissionMap = new GUIContent("ME Map",
                                                                           "Metallic/Thickness(G), Emission Mask(B), Emission Noise(A), Sets a Texture map to use for metallic/thickness and emission. You can also select a color with the color picker. Colors are multiplied over the Texture.");


            public static readonly GUIContent patternMap = new GUIContent("Pattern Map",
                                                                          "Pattern Albedo(RGB).");

            public static readonly GUIContent bumpScaleNotSupported =
                new GUIContent("Bump scale is not supported on mobile platforms");

            public static readonly GUIContent fixNormalNow = new GUIContent("Fix now",
                                                                            "Converts the assigned texture to be a normal map format.");

            public static GUIContent highlightsText = new GUIContent("Specular Highlights",
                                                                     "When enabled, the Material reflects the shine from direct lighting.");

            public static GUIContent reflectionsText =
                new GUIContent("Environment Reflections",
                               "When enabled, the Material samples reflections from the nearest Reflection Probes or Lighting Probe.");

            public static GUIContent environmentMapText =
                  new GUIContent("Environment Map",
                                 "When enabled, the Material samples reflections from the user-defined  Reflection Probes.");

            public static readonly GUIContent queueSlider = new GUIContent("Priority",
                                                                           "Determines the chronological rendering order for a Material. High values are rendered first.");

            public static GUIContent nsMapText =
                new GUIContent("NS Map", "Normal(RGB), Smoothness(A)");

            public static GUIContent LayerTexText =
               new GUIContent("Layer Map", "Extra tex as alpha");

            public static GUIContent panOrPulsateEmissionText =
                new GUIContent("Pan Or Pulsate", "Enable Pan Emission");

            public static readonly GUIContent GradientMap = new GUIContent("Gradient Map",
                                                                         "Gradient Map");
            public static readonly GUIContent GradientMaskMap = new GUIContent("Gradient Mask Map",
                                                                        "Gradient Mask Map");
            public static GUIContent panOrPulsateText(bool isPan) {
                return isPan
                           ? new GUIContent("Pan", "Pan: Tiling(xy) Speed(zw)")
                           : new GUIContent("Pulse", "Pulse: Speed(x), Power Range(yz), Color Variant(a)");
            }

            public static GUIContent smoothnessText = new GUIContent("Smoothness",
                                                                     "Editor Only. Controls the spread of highlights and reflections on the surface.");

            public static GUIContent maskMapText = new GUIContent("Mask Map",
                                                                  "BA Map (A), Enable Mask Map, 0 to use standard specular BRDF.");
        }

        #endregion

        #region Variables

        protected MaterialEditor _materialEditor { get; private set; }
        protected MaterialProperty _surfaceTypeProp { get; set; }
        protected MaterialProperty _blendModeProp;
        protected MaterialProperty _cullingProp;
        protected MaterialProperty _alphaClipProp;
        protected MaterialProperty _alphaCutoffProp;
        protected MaterialProperty _receiveShadowsProp { get; set; }

        // Common Surface Input properties
        protected MaterialProperty _baseColorProp;
        protected MaterialProperty _baseMapProp;
        protected MaterialProperty _bumpMapProp { get; set; }
        protected MaterialProperty _nsMapProp { get; set; }
        protected MaterialProperty _emissionEnabledProp { get; set; }
        protected MaterialProperty _emissionMapProp { get; set; }
        protected MaterialProperty _emissionColorProp { get; set; }
        protected MaterialProperty _emissionPowerProp { get; set; }
        protected MaterialProperty _panOrPulsateEmission { get; set; }
        protected MaterialProperty _panOrPulsateProp { get; set; }

        protected MaterialProperty _enableEnvironmentProp;
        protected MaterialProperty _SHExposureProp;

        protected MaterialProperty _environmentColorProp;
        protected MaterialProperty _PunctualLightSpecularExposureProp;
        protected MaterialProperty _EnvExposureProp;
        protected MaterialProperty _enableEnvironmentMapProp;
        protected MaterialProperty _environmentMap;
        //fur
        protected MaterialProperty _LayerTexProp;
        protected MaterialProperty _FurLengthProp;
        protected MaterialProperty _MaskSmoothProp;
        protected MaterialProperty _NoiseScaleProp;

        protected MaterialProperty _CutoffProp;
        protected MaterialProperty _CutoffEndProp;
        protected MaterialProperty _EdgeFadeProp;
        protected MaterialProperty _GravityProp;
        protected MaterialProperty _GravityStrengthProp;
        protected MaterialProperty _FabricScatterColorProp;
        protected MaterialProperty _FabricScatterScaleProp;
        protected MaterialProperty _ShadowColorProp;
        protected MaterialProperty _ShadowAOProp;
        
        public MaterialProperty HeightProp;
        public MaterialProperty MaskIntensityProp;
        public MaterialProperty _GradientMapProp;
        public MaterialProperty _GradientMaskMapProp;
        public MaterialProperty _GradientColorProp;
        public MaterialProperty _GradientUSpeedProp;
        public MaterialProperty _GradientVSpeedProp;
        public MaterialProperty _EnableGradientProp;

        protected MaterialProperty _enablePatternProp;
        protected MaterialProperty _patternMapProp;



        protected MaterialProperty _enableMaskMap { get; set; }
        public static MaterialProperty _specColProp { get; set; }
        public static MaterialProperty _smoothnessProp { get; set; }


        // Advanced Props
        protected MaterialProperty _queueOffsetProp { get; set; }
        protected MaterialProperty _specHighlights { get; set; }
        protected MaterialProperty _reflections { get; set; }

        protected MaterialProperty _MaterialQualityProp { get; set; }
        protected MaterialProperty _debugProp;

        protected int GetQuality {
            get {
                if (_MaterialQualityProp == null) {
                    return -1;
                }

                return (int)_MaterialQualityProp.floatValue;
            }
        }

        public bool m_FirstTimeApply = true;

        const string k_KeyPrefix = "UniversalRP:Material:UI_State:";

        string m_HeaderStateKey = null;

        // Header foldout states

        SavedBool m_SurfaceOptionsFoldout;
        SavedBool m_SurfaceInputsFoldout;
        SavedBool m_AdvancedFoldout;
        protected static MaterialProperty[] _properties;
        const int queueOffsetRange = 200;

        #endregion


        ////////////////////////////////////
        // General Functions              //
        ////////////////////////////////////

        #region GeneralFunctions

        public abstract void MaterialChanged(Material material);

        public virtual void FindProperties(MaterialProperty[] properties) {
            _properties = properties;
            _surfaceTypeProp = FindProperty(Prop._Surface, properties, false);
            _blendModeProp = FindProperty(Prop._Blend, properties, false);
            _cullingProp = FindProperty(Prop._Cull, properties, false);
            _alphaClipProp = FindProperty(Prop._AlphaClip, properties, false);
            _alphaCutoffProp = FindProperty(Prop._Cutoff, properties, false);
            _receiveShadowsProp = FindProperty(Prop._ReceiveShadows, properties, false);

            _baseColorProp = FindProperty(Prop._BaseColor, properties, false);
            _baseMapProp = FindProperty(Prop._BaseMap, properties, false);
            _bumpMapProp = FindProperty(Prop._BumpMap, properties, false);
            _nsMapProp = FindProperty(Prop._NSMap, properties, false);

            _enableMaskMap = FindProperty(Prop._EnableMaskMap, properties, false);

            _enablePatternProp = FindProperty(Prop._EnablePattern, properties, false);
            _patternMapProp = FindProperty(Prop._PatternMap, properties, false);
            //环境光参数控制
            //_enableEnvironmentProp = FindProperty(Prop._EnableEnvironment, properties, false);
            //_SHExposureProp = FindProperty(Prop._SHExposure, properties, false);
            //_envBDRFFactorProp = FindProperty(Prop._envBDRFFactor, properties, false);

            HeightProp = FindProperty(Prop._Fill, properties, false);
            MaskIntensityProp = FindProperty(Prop._Intensity, properties, false);
            _GradientMapProp = FindProperty(Prop._GradientMap, properties, false);
            _EnableGradientProp = FindProperty(Prop._EnableGradient, properties, false);
            //_GradientMaskMapProp = FindProperty(Prop._GradientMaskMap, properties, false);
            _GradientColorProp = FindProperty(Prop._GradientColor, properties, false);
            _GradientUSpeedProp = FindProperty(Prop._Gradient_U_Speed, properties, false);
            _GradientVSpeedProp = FindProperty(Prop._Gradient_V_Speed, properties, false);

        //--------------------------------------------------------------------------
        _EnvExposureProp = FindProperty(Prop._EnvExposure, properties, false);
            _environmentMap = FindProperty(Prop._EnvironmentMap, properties, false);
            _enableEnvironmentMapProp = FindProperty(Prop._EnableEnvironmentMap, properties, false);
            _PunctualLightSpecularExposureProp = FindProperty(Prop._PunctualLightSpecularExposure, properties, false);
            _environmentColorProp = FindProperty(Prop._EnvironmentColor, properties, false);

            //----fur-----
            _LayerTexProp = FindProperty(Prop._LayerTex, properties, false);
            _FurLengthProp = FindProperty(Prop._FurLength, properties, false);
            _MaskSmoothProp = FindProperty(Prop._MaskSmooth, properties, false);
            _NoiseScaleProp = FindProperty(Prop._NoiseScale, properties, false);
            // _CutoffProp = FindProperty(Prop._CutoffStart, properties, false);
            _CutoffEndProp = FindProperty(Prop._CutoffEnd, properties, false);
            _EdgeFadeProp = FindProperty(Prop._EdgeFade, properties, false);
            _GravityProp = FindProperty(Prop._Gravity, properties, false);
            _GravityStrengthProp = FindProperty(Prop._GravityStrength, properties, false);
            _FabricScatterColorProp = FindProperty(Prop._FabricScatterColor, properties, false);
            _FabricScatterScaleProp = FindProperty(Prop._FabricScatterScale, properties, false);
            _ShadowColorProp = FindProperty(Prop._ShadowColor, properties, false);
            _ShadowAOProp = FindProperty(Prop._ShadowAO, properties, false);

            //---------

            _emissionEnabledProp = FindProperty(Prop._EmissionEnabled, properties, false);
            _emissionMapProp = FindProperty(Prop._EmissionMap, properties, false);
            _emissionColorProp = FindProperty(Prop._EmissionColor, properties, false);
            _emissionPowerProp = FindProperty(Prop._EmissionPower, properties, false);
            _panOrPulsateEmission = FindProperty(Prop._PanOrPulsateEmission, properties, false);
            _panOrPulsateProp = FindProperty(Prop._PanOrPulsate, properties, false);

            // baseColorProp = FindProperty("_BaseColor", properties, false);
            _specColProp = FindProperty(Prop._SpecColor, properties, false);
            _smoothnessProp = FindProperty(Prop._Smoothness, properties, false);

            // Advanced Props
            _specHighlights = FindProperty(Prop._SpecularHighlights, properties, false);
            _reflections = FindProperty(Prop._EnvironmentReflections, properties, false);

            _queueOffsetProp = FindProperty(Prop._QueueOffset, properties, false);
            _MaterialQualityProp = FindProperty(Prop._Material_Quality, properties, false);
            _debugProp = FindProperty(Prop._Debug, properties, false);
        }

        public override void OnGUI(MaterialEditor materialEditorIn, MaterialProperty[] properties) {
            if (materialEditorIn == null)
                throw new ArgumentNullException("materialEditorIn");

            FindProperties(properties); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            _materialEditor = materialEditorIn;
            var material = _materialEditor.target as Material;

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a universal shader.
            if (m_FirstTimeApply) {
                OnOpenGUI(material, materialEditorIn);
                m_FirstTimeApply = false;
            }

            DrawDebugMode(material);
            DrawMaterialQuality(material);
            ShaderPropertiesGUI(material);
        }

        protected virtual string[] GetDebugMode => new[] {
                                                             "NONE", //0
                                                             "Albedo", //1
                                                             "Metallic", //2
                                                             "Smoothness", //3
                                                             "NormalTS", //4
                                                             "Occlusion", //5
                                                             "Specular", //6
                                                             "Emission", //7
                                                             "Alpha", //8
                                                             "VertexLighting", //9
                                                             "BakedGI", //10

                                                             "BRDF_Diffuse", //11
                                                             "BRDF_Specular", //12
                                                             "BRDF_BakedGI", //13
                                                             "BRDF_DirectPBR", //14
                                                             "BRDF_GI", //15
                                                             "BRDF_IndirectDiffuse", //16
                                                             "BRDF_IndirectSpecular", //17


                                                             "BRDF_AdditionalLight", //18
                                                         };

        public virtual void DrawDebugMode(Material mat) {
            if (_debugProp != null) {
                EditorGUI.BeginChangeCheck();

                var debug = DoPopup(new GUIContent("DEBUG"), _debugProp, GetDebugMode, 0);
                if (EditorGUI.EndChangeCheck()) {
                    _materialEditor.RegisterPropertyChangeUndo("DEBUG-MODE");
                    _debugProp.floatValue = debug;
                }
            }
        }

        public virtual void DrawMaterialQuality(Material mat) {
            if (_MaterialQualityProp == null) return;
            EditorGUI.BeginChangeCheck();
            DoPopup(new GUIContent("Quality"), _MaterialQualityProp, new[] { "High", "Medium", "Low" });
            EditorGUILayout.Space(8);
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        public virtual void OnOpenGUI(Material material, MaterialEditor materialEditor) {
            // Foldout states
            m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
            m_SurfaceOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceOptionsFoldout", true);
            m_SurfaceInputsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceInputsFoldout", true);
            m_AdvancedFoldout = new SavedBool($"{m_HeaderStateKey}.AdvancedFoldout", false);

            foreach (var obj in materialEditor.targets)
                MaterialChanged((Material)obj);
        }

        public void ShaderPropertiesGUI(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            EditorGUI.BeginChangeCheck();

            m_SurfaceOptionsFoldout.value =
                EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceOptionsFoldout.value, Styles.SurfaceOptions);
            if (m_SurfaceOptionsFoldout.value) {
                DrawSurfaceOptions(material);
                EditorGUILayout.Space();
            }

            EditorGUILayout.EndFoldoutHeaderGroup();

            m_SurfaceInputsFoldout.value =
                EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceInputsFoldout.value, Styles.SurfaceInputs);
            if (m_SurfaceInputsFoldout.value) {
                DrawSurfaceInputs(material);
                EditorGUILayout.Space();
            }

            EditorGUILayout.EndFoldoutHeaderGroup();

            m_AdvancedFoldout.value =
                EditorGUILayout.BeginFoldoutHeaderGroup(m_AdvancedFoldout.value, Styles.AdvancedLabel);
            if (m_AdvancedFoldout.value) {
                DrawAdvancedOptions(material);
                EditorGUILayout.Space();
            }

            EditorGUILayout.EndFoldoutHeaderGroup();

            DrawAdditionalFoldouts(material);

            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        #endregion

        ////////////////////////////////////
        // Drawing Functions              //
        ////////////////////////////////////

        #region DrawingFunctions

        public virtual void DrawSurfaceOptions(Material material) {
            EditorGUI.BeginChangeCheck();
            if (_surfaceTypeProp != null) {
                DoPopup(Styles.surfaceType, _surfaceTypeProp, Enum.GetNames(typeof(SurfaceType)));
                if ((SurfaceType)material.GetFloat(Prop._Surface) == SurfaceType.Transparent && _blendModeProp != null)
                    DoPopup(Styles.blendingMode, _blendModeProp, Enum.GetNames(typeof(BlendMode)));
            }

            DrawCullingProp(material);

            if (_alphaClipProp != null && _alphaCutoffProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _alphaClipProp.hasMixedValue;
                var alphaClipEnabled = EditorGUILayout.Toggle(Styles.alphaClipText, _alphaClipProp.floatValue == 1);
                if (EditorGUI.EndChangeCheck())
                    _alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
                EditorGUI.showMixedValue = false;

                if (_alphaClipProp.floatValue == 1)
                    _materialEditor.ShaderProperty(_alphaCutoffProp, Styles.alphaClipThresholdText, 1);
            }

            if (_receiveShadowsProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _receiveShadowsProp.hasMixedValue;
                var receiveShadows =
                    EditorGUILayout.Toggle(Styles.receiveShadowText, _receiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck())
                    _receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
                EditorGUI.showMixedValue = false;
            }

            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        protected virtual void DrawCullingProp(Material material) {
            if (_cullingProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _cullingProp.hasMixedValue;
                var culling = (RenderFace)_cullingProp.floatValue;
                culling = (RenderFace)EditorGUILayout.EnumPopup(Styles.cullingText, culling);
                if (EditorGUI.EndChangeCheck()) {
                    _materialEditor.RegisterPropertyChangeUndo(Styles.cullingText.text);
                    _cullingProp.floatValue = (float)culling;
                    material.doubleSidedGI = (RenderFace)_cullingProp.floatValue != RenderFace.Front;
                }

                EditorGUI.showMixedValue = false;
            }
        }

        public virtual void DrawSurfaceInputs(Material material) {
            EditorGUI.BeginChangeCheck();
            if (_baseMapProp != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                if (_baseColorProp == null) {
                    _materialEditor.TexturePropertySingleLine(Styles.baseMap, _baseMapProp);
                } else {
                    _materialEditor.TexturePropertySingleLine(Styles.baseMap, _baseMapProp, _baseColorProp);
                }

                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(LegacyProp._MainTex)) {
                    material.SetTexture(LegacyProp._MainTex, _baseMapProp.textureValue);
                    var baseMapTiling = _baseMapProp.textureScaleAndOffset;
                    material.SetTextureScale(LegacyProp._MainTex, new Vector2(baseMapTiling.x, baseMapTiling.y));
                    material.SetTextureOffset(LegacyProp._MainTex, new Vector2(baseMapTiling.z, baseMapTiling.w));
                }
            }

            DrawBaseProperties(material);
            DrawTileOffset(_materialEditor, _baseMapProp);
            if (EditorGUI.EndChangeCheck()) {
                MaterialChanged(material);
            }
        }

        public virtual void DrawAdvancedOptions(Material material) {
            _materialEditor.EnableInstancingField();
            if (_reflections != null && _specHighlights != null) {
                EditorGUI.BeginChangeCheck();
                _materialEditor.ShaderProperty(_specHighlights, Styles.highlightsText);
                _materialEditor.ShaderProperty(_reflections, Styles.reflectionsText);
                if (EditorGUI.EndChangeCheck()) {
                    MaterialChanged(material);
                }
            } else {
                if (_specHighlights != null) {
                    EditorGUI.BeginChangeCheck();
                    _materialEditor.ShaderProperty(_specHighlights, Styles.highlightsText);
                    if (EditorGUI.EndChangeCheck()) {
                        MaterialChanged(material);
                    }
                }
            }

            if (_queueOffsetProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _queueOffsetProp.hasMixedValue;
                var queue = EditorGUILayout.IntSlider(Styles.queueSlider, (int)_queueOffsetProp.floatValue,
                                                      -queueOffsetRange, queueOffsetRange);
                if (EditorGUI.EndChangeCheck())
                    _queueOffsetProp.floatValue = queue;
                EditorGUI.showMixedValue = false;
            }
        }

        public virtual void DrawAdditionalFoldouts(Material material) {
        }

        public virtual void DrawBaseProperties(Material material) {
            DrawEnableMaskMap();
            EditorGUILayout.Space(8);
            DrawNSArea(material);
            DrawEmissionArea();
            DrawPatternProp();
            EditorGUILayout.Space(8);
    
          
            DrawEnvironmentMap();
            DrawSpecColor(material);
        }

        public void DrawPatternProp() {
            if (_enablePatternProp == null || _patternMapProp == null) {
                return;
            }

            EditorGUILayout.Space(8);
            var enablePatternProp = DoToggleField(_enablePatternProp, new GUIContent("Pattern"), 0);
            if (enablePatternProp) {
                _materialEditor.TexturePropertySingleLine(Styles.patternMap, _patternMapProp);
            }
        }
      
      
        public void DrawEnvironmentMap()
        {
            if (_enableEnvironmentMapProp == null||_environmentMap==null) 
            {
                return;
            }
            EditorGUILayout.Space(8);
            var enableEnvironmentMapProp = DoToggleField(_enableEnvironmentMapProp, new GUIContent("EnvironmentMap"), 0);
            if (enableEnvironmentMapProp)
            {
                EditorGUILayout.Space(4);
                DoSliderField(_EnvExposureProp, 0, 1);
                EditorGUILayout.Space(4);
                DoSliderField(_PunctualLightSpecularExposureProp, 1, 10);
                if(_materialEditor && _environmentMap != null && _environmentColorProp != null)
                    _materialEditor.TexturePropertyWithHDRColor(Styles.environmentMapText, _environmentMap,_environmentColorProp,false);
                   
            }
          
           
        }
        public void DrawGradientArea(Material material)
        {
            var enableGradientProp = DoToggleField(_EnableGradientProp, "EnableGradient", 0);
            if (enableGradientProp)
            {
                DoSliderField(HeightProp, 0, 1);
                DoSliderField(MaskIntensityProp, 0, 10);
                DoSliderField(_GradientUSpeedProp,-2,2);
                DoSliderField(_GradientVSpeedProp, -2, 2);

                if (_materialEditor != null)
                {
                    if (_GradientMapProp != null)
                        _materialEditor.TexturePropertySingleLine(Styles.GradientMap, _GradientMapProp, _GradientColorProp);
                    if (material.HasProperty(Prop._GradientMap))
                    {
                        material.SetTexture(Prop._GradientMap, _GradientMapProp.textureValue);
                        var GradientMapTiling = _GradientMapProp.textureScaleAndOffset;
                        material.SetTextureScale(Prop._GradientMap, new Vector2(GradientMapTiling.x, GradientMapTiling.y));
                        material.SetTextureOffset(Prop._GradientMap, new Vector2(GradientMapTiling.z, GradientMapTiling.w));
                    }
                    DrawTileOffset(_materialEditor, _GradientMapProp);
                    //if (_GradientMaskMapProp != null)
                    //    _materialEditor.TexturePropertySingleLine(Styles.GradientMaskMap, _GradientMaskMapProp);
                    //if (material.HasProperty(Prop._GradientMaskMap))
                    //{
                    //    material.SetTexture(Prop._GradientMaskMap, _GradientMaskMapProp.textureValue);
                    //    var GradientMaskMapTiling = _GradientMaskMapProp.textureScaleAndOffset;
                    //    material.SetTextureScale(Prop._GradientMaskMap, new Vector2(GradientMaskMapTiling.x, GradientMaskMapTiling.y));
                    //    material.SetTextureOffset(Prop._GradientMaskMap, new Vector2(GradientMaskMapTiling.z, GradientMaskMapTiling.w));
                    //}
                    //DrawTileOffset(_materialEditor, _GradientMaskMapProp);
                }
                

                
            }

        }
     

        public void DrawEnableMaskMap() {
            if (_enableMaskMap == null) {
                return;
            }

            DoToggleField(_enableMaskMap, Styles.maskMapText, 2);
        }

        public void DrawSpecColor(Material material) {
            if (GetQuality == LOW_QUALITY) {
                return;
            }

            if (_specColProp != null) {
                DoColorField(_specColProp);
            }

            if (_smoothnessProp != null) {
                DoSliderField(_smoothnessProp, Styles.smoothnessText, 0, 1);
            }

            if (_specColProp != null || _smoothnessProp != null) {
                EditorGUILayout.Space(8);
            }
        }

        public void DrawEmissionArea() {
            if (_emissionEnabledProp == null || _emissionMapProp == null || _emissionColorProp == null) {
                return;
            }

            _materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, _emissionMapProp,
                                                        _emissionColorProp,
                                                        false);
            var hadEmissionTexture = _emissionMapProp.textureValue != null;
            var emission = _materialEditor.EmissionEnabledProperty();
            _emissionEnabledProp.floatValue = emission ? 1 : 0;
            if (hadEmissionTexture && emission) {
                DoSliderField(_emissionPowerProp, 0, 5, 2);
                var pan = DoPopup(Styles.panOrPulsateEmissionText, _panOrPulsateEmission, new[] {"Pan", "Pulsate"}, 2);
                var panText = Styles.panOrPulsateText(pan == 0);
                EditorGUI.indentLevel += 2;
                EditorGUILayout.HelpBox(panText.tooltip, MessageType.Info);
                _materialEditor.VectorProperty(_panOrPulsateProp, panText.text);
                EditorGUI.indentLevel -= 2;
            }
        }
       
       public void DrawFurArea()
        {
            //if (_LayerTexProp != null)
            //{

                //if (material.HasProperty(Prop._LayerTex))
                //{
                //    material.SetTexture(Prop._LayerTex, _LayerTexProp.textureValue);
                //    var LayerTexTiling = _LayerTexProp.textureScaleAndOffset;
                //    material.SetTextureScale(Prop._LayerTex, new Vector2(LayerTexTiling.x, LayerTexTiling.y));
                //    material.SetTextureOffset(Prop._LayerTex, new Vector2(LayerTexTiling.z, LayerTexTiling.w));

                //}
               
                _materialEditor.TexturePropertySingleLine(Styles.LayerTexText, _LayerTexProp);
                DrawTileOffset(_materialEditor, _LayerTexProp);
              
                DoSliderField(_FurLengthProp, 0, 1);
                DoSliderField(_MaskSmoothProp, 0, 1);
                DoSliderField(_NoiseScaleProp, 1, 100);

                EditorGUILayout.BeginHorizontal();
                DoSliderField(_CutoffProp, 0, 1);

                DoSliderField(_CutoffEndProp, 0, 1);
                EditorGUILayout.EndHorizontal();
                DoSliderField(_EdgeFadeProp, 0, 1);
                _materialEditor.VectorProperty(_GravityProp, "Gravity");
                DoSliderField(_GravityStrengthProp, 0, 1);
                EditorGUILayout.BeginHorizontal();
                DoSliderField(_FabricScatterScaleProp, 0, 1);
                DoColorField(_FabricScatterColorProp);
                EditorGUILayout.EndHorizontal();
                EditorGUILayout.BeginHorizontal();
                DoColorField(_ShadowColorProp);
                DoSliderField(_ShadowAOProp, 0, 1);
                EditorGUILayout.EndHorizontal();
            // }

        }

        public void DrawNSArea(Material material) {
            if (GetQuality == LOW_QUALITY || _nsMapProp == null) {
                return;
            }

            _materialEditor.TexturePropertySingleLine(Styles.nsMapText, _nsMapProp);
            EditorGUILayout.Space(8);
        }

        public static void DrawNormalArea(MaterialEditor materialEditor, MaterialProperty bumpMap,
                                          MaterialProperty bumpMapScale = null) {
            if (bumpMapScale != null) {
                materialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap,
                                                         bumpMap.textureValue != null ? bumpMapScale : null);
                if (bumpMapScale.floatValue != 1 &&
                    UnityEditorInternal.InternalEditorUtility.IsMobilePlatform(
                                                                               EditorUserBuildSettings
                                                                                  .activeBuildTarget))
                    if (materialEditor.HelpBoxWithButton(Styles.bumpScaleNotSupported, Styles.fixNormalNow))
                        bumpMapScale.floatValue = 1;
            } else {
                materialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap);
            }
        }

        protected virtual void DrawEmissionProperties(Material material, bool keyword) {
            var emissive = true;
            var hadEmissionTexture = _emissionMapProp.textureValue != null;

            if (!keyword) {
                _materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, _emissionMapProp, _emissionColorProp,
                                                            false);
            } else {
                // Emission for GI?
                emissive = _materialEditor.EmissionEnabledProperty();

                EditorGUI.BeginDisabledGroup(!emissive);
                {
                    // Texture and HDR color controls
                    _materialEditor.TexturePropertyWithHDRColor(Styles.emissionMap, _emissionMapProp,
                                                                _emissionColorProp,
                                                                false);
                }
                EditorGUI.EndDisabledGroup();
            }

            // If texture was assigned and color was black set color to white
            var brightness = _emissionColorProp.colorValue.maxColorComponent;
            if (_emissionMapProp.textureValue != null && !hadEmissionTexture && brightness <= 0f)
                _emissionColorProp.colorValue = Color.white;

            // UniversalRP does not support RealtimeEmissive. We set it to bake emissive and handle the emissive is black right.
            if (emissive) {
                material.globalIlluminationFlags = MaterialGlobalIlluminationFlags.BakedEmissive;
                if (brightness <= 0f)
                    material.globalIlluminationFlags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }

        protected static void DrawTileOffset(MaterialEditor materialEditor, MaterialProperty textureProp) {
            materialEditor.TextureScaleOffsetProperty(textureProp);
        }

        #endregion

        ////////////////////////////////////
        // Material Data Functions        //
        ////////////////////////////////////s

        #region MaterialDataFunctions

        public void SetMaterialKeywords(Material material, Action<Material> shadingModelFunc = null,
                                        Action<Material> shaderFunc = null) {
            // Clear all keywords for fresh start
            material.shaderKeywords = null;
            // Setup blending - consistent across all Universal RP shaders
            SetupMaterialBlendMode(material);


            // Receive Shadows
            if (material.HasProperty(Prop._ReceiveShadows)) {
                CoreUtils.SetKeyword(material, Keyword._RECEIVE_SHADOWS_OFF,
                                     material.GetFloat(Prop._ReceiveShadows) == 0.0f);
            }

            // Emission
            if (material.HasProperty(Prop._EmissionColor))
                MaterialEditor.FixupEmissiveFlag(material);

            var shouldEmissionBeEnabled =
                (material.globalIlluminationFlags & MaterialGlobalIlluminationFlags.EmissiveIsBlack) == 0;

            var emission = false;
            if (material.HasProperty(Prop._EmissionEnabled)) {
                emission = material.GetFloat(Prop._EmissionEnabled) > 0.5;
                CoreUtils.SetKeyword(material, Keyword._EMISSION, emission);
            }

            if (emission) {
                var emColor = material.GetColor(Prop._EmissionColor);
                emColor.a = material.GetFloat(Prop._EmissionPower);
                material.SetColor(Prop._EmissionColor, emColor);
            }

            if (material.HasProperty(Prop._EnablePattern)) {
                CoreUtils.SetKeyword(material, Keyword._PATTERNMAP,
                                     material.GetFloat(Prop._EnablePattern) == 1.0f);
                // CoreUtils.SetKeyword(material, Keyword._PATTERNMAP,
                //                      material.GetFloat(Prop._EnablePattern) == 1.0f &&
                //                      material.GetTexture(Prop._PatternMap) != null);
            }
            if (material.HasProperty(Prop._EnableGradient))
            {
                CoreUtils.SetKeyword(material, Keyword._ENABLEGRADIENT, material.GetFloat(Prop._EnableGradient) == 1.0f);

            }
            if (emission && material.HasProperty(Prop._PanOrPulsateEmission)) {
                var state = material.GetFloat(Prop._PanOrPulsateEmission) == 0.0f;
                CoreUtils.SetKeyword(material, Keyword._PAN, state);
            }
      
            //if (material.HasProperty(Prop._EnableEnvironment))
            //{
            //    var state = material.GetFloat(Prop._EnableEnvironment)==1.0f;
            //    CoreUtils.SetKeyword(material, Keyword._ENVIRONMENT, state);
            //}
            //EnvironmentMap
            if (material.HasProperty(Prop._EnvironmentMap))
            {
                var state = material.GetFloat(Prop._EnableEnvironmentMap) == 1.0f;
                CoreUtils.SetKeyword(material, Keyword._ENVIRONMENTMAP,state);
            }

            if (material.HasProperty(Prop._EnableSkin))
            {
                var state = material.GetFloat(Prop._EnableSkin) == 1.0f;
                CoreUtils.SetKeyword(material, Keyword._ENABLESKIN, state); 
            }
            // Normal Map
            if (GetQuality != LOW_QUALITY) {
                if (material.HasProperty(Prop._BumpMap)) {
                    // CoreUtils.SetKeyword(material, Keyword._NORMALMAP, material.GetTexture(Prop._BumpMap));
                } else if (material.HasProperty(Prop._NSMap)) {
                   CoreUtils.SetKeyword(material, Keyword._NORMALMAP, material.GetTexture(Prop._NSMap));
                }

                if (material.HasProperty(Prop._SpecularHighlights)) {
                    CoreUtils.SetKeyword(material, Keyword._SPECULARHIGHLIGHTS_OFF,
                                         material.GetFloat(Prop._SpecularHighlights) == 0.0f);
                }
            }

            if (material.HasProperty(Prop._SpecColor)) {
                // CoreUtils.SetKeyword(material, Keyword._SPECULAR_COLOR, true);
                if (material.HasProperty(Prop._Smoothness)) {
                    var col = material.GetColor(Prop._SpecColor);
                    col.a = material.GetFloat(Prop._Smoothness);
                    material.SetColor(Prop._SpecColor, col);
                    // Debug.Log($"Spec Color {col}");
                }
            }

            // Mask Map
            if (material.HasProperty(Prop._EnableMaskMap)) {
                CoreUtils.SetKeyword(material, Keyword._MASKMAP, material.GetFloat(Prop._EnableMaskMap) == 1);
            }

            if (material.HasProperty(Prop._IridescenceThicknessMap))
                CoreUtils.SetKeyword(material, Keyword._IRIDESCENCE_THICKNESSMAP, material.GetTexture(Prop._IridescenceThicknessMap));

            if (material.HasProperty(Prop._EnvironmentReflections))
                CoreUtils.SetKeyword(material, Keyword._ENVIRONMENTREFLECTIONS_OFF,
                                     material.GetFloat(Prop._EnvironmentReflections) == 0.0f);


            SetMaterialQuality(material);
            // Shader specific keyword functions
            shadingModelFunc?.Invoke(material);
            shaderFunc?.Invoke(material);
        }

        public virtual void SetMaterialQuality(Material material) {
            var quality = GetQuality;
            if (quality == -1) {
                return;
            }

            switch (quality) {
                case 0:
                    material.shader.maximumLOD = HIGH_QUALITY;
                    break;
                case 1:
                    material.shader.maximumLOD = MEDIUM_QUALITY;
                    break;
                case 2:
                    material.shader.maximumLOD = LOW_QUALITY;
                    break;
            }

            //  Debug.Log($"{material.shader.name}: Set LOD {material.shader.maximumLOD}");
        }

        public static void SetupMaterialBlendMode(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            var alphaClip = false;

            if (material.HasProperty(Prop._AlphaClip)) {
                alphaClip = material.GetFloat(Prop._AlphaClip) == 1;
                if (alphaClip) {
                    material.EnableKeyword(Keyword._ALPHATEST_ON);
                } else {
                    material.DisableKeyword(Keyword._ALPHATEST_ON);
                }
            }

            var queueOffset = 0; // queueOffsetRange;
            if (material.HasProperty(Prop._QueueOffset))
                queueOffset = Mathf.Clamp((int)material.GetFloat(Prop._QueueOffset) ,- queueOffsetRange,queueOffsetRange);

            SurfaceType surfaceType = SurfaceType.Opaque;
            if (material.HasProperty(Prop._Surface)) {
                surfaceType = (SurfaceType) material.GetFloat(Prop._Surface);
            }

            if (surfaceType == SurfaceType.Opaque) {
                if (alphaClip) {
                    material.renderQueue = (int) RenderQueue.AlphaTest;
                    material.SetOverrideTag(Tag.RenderType, Tag.TransparentCutout);
                } else {
                    material.renderQueue = (int) RenderQueue.Geometry;
                    material.SetOverrideTag(Tag.RenderType, Tag.Opaque);
                }

                material.renderQueue += queueOffset;
                material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.One);
                material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.Zero);
                material.SetInt(Prop._ZWrite, 1);
                material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
                material.SetShaderPassEnabled(Pass.ShadowCaster, true);
            } else {
                var blendMode = (BlendMode) material.GetFloat(Prop._Blend);
                var queue = (int) RenderQueue.Transparent;

                // Specific Transparent Mode Settings
                switch (blendMode) {
                    case BlendMode.Alpha:
                        material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                        material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Premultiply:
                        material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.One);
                        material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        material.EnableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Additive:
                        material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                        material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.One);
                        material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Multiply:
                        material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.DstColor);
                        material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.Zero);
                        material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
                        material.EnableKeyword(Keyword._ALPHAMODULATE_ON);
                        break;
                }

                // General Transparent Material Settings
                material.SetOverrideTag(Tag.RenderType, Tag.Transparent);
                material.SetInt(Prop._ZWrite, 0);
                material.renderQueue = queue + queueOffset;
                material.SetShaderPassEnabled(Pass.ShadowCaster, false);
            }
        }

        public static void SetChangeColorKeyword(Material material) {
            if (material.HasProperty(Prop._ColorMode)) {
                var mode = material.GetFloat(Prop._ColorMode);
                CoreUtils.SetKeyword(material, Keyword._COLOR_SOFTLIGHT, mode == 1.0f);
            }
        }

        #endregion

        ////////////////////////////////////
        // Helper Functions               //
        ////////////////////////////////////

        #region HelperFunctions

        public static void DoFloatField(MaterialProperty prop, int indent = 1) {
            if (prop == null) {
                return;
            }

            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;

            var value = prop.floatValue;
            value = EditorGUILayout.FloatField(prop.displayName, value);
            if (EditorGUI.EndChangeCheck()) {
                prop.floatValue = value;
            }

            EditorGUI.showMixedValue = false;
            EditorGUI.indentLevel -= indent;
        }

        public void DoVectorField(MaterialProperty prop, GUIContent content, int indent = 1) {
            if (prop == null) {
                return;
            }

            _materialEditor.ShaderProperty(prop, content, indent);
        }

        public void DoVectorField(MaterialProperty prop, string title, int indent = 1) {
            if (prop == null) {
                return;
            }

            EditorGUI.indentLevel += indent;
            _materialEditor.VectorProperty(prop, title);
            EditorGUI.indentLevel -= indent;
        }

        public void DoTextureField(MaterialProperty prop, string title = "", int indent = 0) {
            if (prop == null) {
                return;
            }

            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            _materialEditor.TexturePropertySingleLine(GetGuiContent(prop, title), prop);
            EditorGUI.showMixedValue = false;
            EditorGUI.indentLevel -= indent;
        }

        public void DoSliderField(MaterialProperty prop, float leftValue, float rightValue,
                                  int indent = 1) {
            if (prop == null) {
                return;
            }

            DoSliderField(prop, new GUIContent(prop.displayName), leftValue, rightValue, indent);
        }

        public static void DoSliderField(MaterialProperty prop, GUIContent title, float leftValue, float rightValue,
                                         int indent = 1) {
            if (prop == null) {
                return;
            }

            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;

            var value = prop.floatValue;
            value = EditorGUILayout.Slider(title, value, leftValue, rightValue);
            if (EditorGUI.EndChangeCheck()) {
                prop.floatValue = value;
            }

            EditorGUI.showMixedValue = false;
            EditorGUI.indentLevel -= indent;
        }

        public static void DoColorField(MaterialProperty prop, int indent = 1, bool showEyeDropper = true,
                                        bool showAlpha = false,
                                        bool hdr = false) {
            if (prop == null) {
                return;
            }

            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();

            var value = prop.colorValue;
            value = EditorGUILayout.ColorField(new GUIContent(prop.displayName), value, showEyeDropper, showAlpha, hdr);
            if (EditorGUI.EndChangeCheck()) {
                prop.colorValue = value;
            }

            EditorGUI.indentLevel -= indent;
        }

        public static bool DoToggleField(MaterialProperty prop, string title, int indent = 0) {
            return prop != null && DoToggleField(prop, new GUIContent(title), indent);
        }

        public static bool DoToggleField(MaterialProperty prop, GUIContent content, int indent = 0) {
            if (prop == null) {
                return false;
            }

            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            var enable = EditorGUILayout.Toggle(content, prop.floatValue == 1.0f);
            if (EditorGUI.EndChangeCheck())
                prop.floatValue = enable ? 1.0f : 0.0f;
            EditorGUI.showMixedValue = false;
            EditorGUI.indentLevel -= indent;
            return enable;
        }

        public static void TwoFloatSingleLine(GUIContent title, MaterialProperty prop1, GUIContent prop1Label,
                                              MaterialProperty prop2, GUIContent prop2Label,
                                              MaterialEditor materialEditor, float labelWidth = 30f) {
            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop1.hasMixedValue || prop2.hasMixedValue;
            var rect = EditorGUILayout.GetControlRect();
            EditorGUI.PrefixLabel(rect, title);
            var indent = EditorGUI.indentLevel;
            var preLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUI.indentLevel = 0;
            EditorGUIUtility.labelWidth = labelWidth;

            var propRect1 = new Rect(rect.x + preLabelWidth, rect.y,
                                     (rect.width - preLabelWidth) * 0.5f, EditorGUIUtility.singleLineHeight);

            var prop1val = EditorGUI.FloatField(propRect1, prop1Label, prop1.floatValue);

            var propRect2 = new Rect(propRect1.x + propRect1.width, rect.y,
                                     propRect1.width, EditorGUIUtility.singleLineHeight);

            var prop2val = EditorGUI.FloatField(propRect2, prop2Label, prop2.floatValue);
            EditorGUI.indentLevel = indent;
            EditorGUIUtility.labelWidth = preLabelWidth;
            if (EditorGUI.EndChangeCheck()) {
                materialEditor.RegisterPropertyChangeUndo(title.text);
                prop1.floatValue = prop1val;
                prop2.floatValue = prop2val;
            }

            EditorGUI.showMixedValue = false;
        }

        public float DoPopup(GUIContent label, MaterialProperty property, string[] options, int indent = 1) {
            return DoPopup(label, property, options, _materialEditor, indent);
        }

        protected static float DoPopup(GUIContent label, MaterialProperty property, string[] options,
                                       MaterialEditor materialEditor, int indent = 1) {
            if (property == null)
                throw new ArgumentNullException("property");
            EditorGUI.showMixedValue = property.hasMixedValue;
            var mode = property.floatValue;
            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            mode = EditorGUILayout.Popup(label, (int) mode, options);
            if (EditorGUI.EndChangeCheck()) {
                materialEditor.RegisterPropertyChangeUndo(label.text);
                property.floatValue = mode;
            }

            EditorGUI.showMixedValue = false;
            EditorGUI.indentLevel -= indent;
            return property.floatValue;
        }

        public static void DoHeader(string label, int indent = 1) {
            EditorGUI.indentLevel += indent;
            GUILayout.Label(label, EditorStyles.boldLabel);
            EditorGUI.indentLevel -= indent;
        }

        // Helper to show texture and color properties
        protected Rect TextureColorProps(MaterialEditor materialEditor, GUIContent label,
                                         MaterialProperty textureProp, MaterialProperty colorProp,
                                         bool hdr = false, bool hideColorIfTex = false) {
            var rect = EditorGUILayout.GetControlRect();
            if (textureProp == null) {
                return rect;
            }

            EditorGUI.showMixedValue = textureProp.hasMixedValue;
            materialEditor.TexturePropertyMiniThumbnail(rect, textureProp, label.text, label.tooltip);
            EditorGUI.showMixedValue = false;

            // if (((hideColorIfTex && textureProp.textureValue == null) || (!hideColorIfTex)) && colorProp != null) {
            if (colorProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = colorProp.hasMixedValue;
                var indentLevel = EditorGUI.indentLevel;
                EditorGUI.indentLevel = 0;
                var rectAfterLabel = new Rect(rect.x + EditorGUIUtility.labelWidth, rect.y,
                                              EditorGUIUtility.fieldWidth, EditorGUIUtility.singleLineHeight);
                var col = EditorGUI.ColorField(rectAfterLabel, GUIContent.none, colorProp.colorValue, true,
                                               false, hdr);
                EditorGUI.indentLevel = indentLevel;
                if (EditorGUI.EndChangeCheck()) {
                    materialEditor.RegisterPropertyChangeUndo(colorProp.displayName);
                    colorProp.colorValue = col;
                }

                EditorGUI.showMixedValue = false;
            }

            return rect;
        }

        // Copied from shaderGUI as it is a protected function in an abstract class, unavailable to others
        protected new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties) {
            return FindProperty(propertyName, properties, true);
        }

        // Copied from shaderGUI as it is a protected function in an abstract class, unavailable to others
        protected new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties,
                                                           bool propertyIsMandatory) {
            for (var index = 0; index < properties.Length; ++index) {
                if (properties[index] != null && properties[index].name == propertyName)
                    return properties[index];
            }

            if (propertyIsMandatory)
                throw new ArgumentException("Could not find MaterialProperty: '" + propertyName +
                                            "', Num properties: " + (object) properties.Length);
            return null;
        }

        protected static GUIContent GetGuiContent(MaterialProperty prop, string title = "") {
            if (prop == null) {
                return GUIContent.none;
            }

            if (string.IsNullOrEmpty(title)) {
                title = prop.name;
            }

            return new GUIContent(title, prop.displayName);
        }

        #endregion
    }
}