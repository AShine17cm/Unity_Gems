using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public abstract class VFXXShaderGUI : ShaderGUI {
        #region EnumsAndClasses

        public enum SurfaceType {
            Opaque,
            Transparent
        }
        public enum ModeType
        {
            Particle,
            Model
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

        public enum MaterialType
        {
            Add,
            Blend
        }
        //public const string AddName = "Add";
        //public const string BlendName = "Blend";

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
            public static readonly GUIContent ModeType = new GUIContent("Mode Type",
                                                                          "Select a Mode type for your texture. Choose between Particle or Model.");
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

            public static readonly GUIContent baseMap = new GUIContent("Base Map");

            public static readonly GUIContent Fresnel = new GUIContent("Fresnel", "When enabled, baseMap  and  fresnel  merge, When disabled , only fresnel .");

            public static readonly GUIContent maskMap = new GUIContent("Mask Map");

            public static readonly GUIContent pannerMap = new GUIContent("Panner Map");

            public static readonly GUIContent dissloveMap = new GUIContent("Disslove Map");

            public static readonly GUIContent offsetMap = new GUIContent("Offset Map");

            public static readonly GUIContent fixNormalNow = new GUIContent("Fix now",
                                                                            "Converts the assigned texture to be a normal map format.");

            public static readonly GUIContent queueSlider = new GUIContent("Priority",
                                                                           "Determines the chronological rendering order for a Material. High values are rendered first.");
            public static GUIContent ADDOrBLENDText(bool isAdd) {
                return isAdd
                        ? new GUIContent("Add")
                        : new GUIContent("Blend");
            }
        
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
        protected MaterialProperty baseMapProp { get; set; }
        protected MaterialProperty maskMapProp { get; set; }
        protected MaterialProperty pannerMapProp { get; set; }
        protected MaterialProperty dissloveMapProp { get; set; }
        //protected MaterialProperty offsetMapProp { get; set; }

        protected MaterialProperty _baseColorProp;


        protected MaterialProperty _Extrusion { get; set; }
        protected MaterialProperty _MainUVSpeedAndRota { get; set; }
        protected MaterialProperty _MaskUVSpeedAndRota { get; set; }
        protected MaterialProperty _PannerUVSpeedAndRota { get; set; }
      //  protected MaterialProperty _OffsetUVSpeedAndRota { get; set; }

        protected MaterialProperty _DissloveUVSpeedAndRota { get; set; }

        protected MaterialProperty _MainUOffset { get; set; }
        protected MaterialProperty _MainVOffset { get; set; }

        protected MaterialProperty _Hardness { get; set; }

        protected MaterialProperty _Edgewidth { get; set; }
        protected MaterialProperty _EdgeColor { get; set; }
        protected MaterialProperty _BaseColor { get; set; }


        protected MaterialProperty _Fresnel { get; set; }

        protected MaterialProperty _FresnelColor { get; set; }

        protected MaterialProperty _FresnelWidth { get; set; }

        protected MaterialProperty _FresnelIntensity { get; set; }

        protected MaterialProperty _Mode { get; set; }

        protected MaterialProperty _MaterialModeProp { get; set; }
        // Advanced Props
        protected MaterialProperty _queueOffsetProp { get; set; }
        protected MaterialProperty _specHighlights { get; set; }
        protected MaterialProperty _reflections { get; set; }

        protected MaterialProperty _debugProp;

    

        public bool m_FirstTimeApply = true;

        const string k_KeyPrefix = "UniversalRP:Material:UI_State:";

        string m_HeaderStateKey = null;

        // Header foldout states

        SavedBool m_SurfaceOptionsFoldout;
        SavedBool m_SurfaceInputsFoldout;
        SavedBool m_AdvancedFoldout;

        protected static MaterialProperty[] _properties;
        const int queueOffsetRange = 10;

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
            baseMapProp = FindProperty(Prop._BaseMap, properties, false);
            maskMapProp = FindProperty(Prop._MaskMap, properties, false);
            pannerMapProp = FindProperty(Prop._PannerTex, properties, false);
            dissloveMapProp = FindProperty(Prop._DissloveTex, properties, false);
            _MainUVSpeedAndRota = FindProperty("_MainUVSpeedAndRota", properties, false);
            _Extrusion = FindProperty("_Extrusion", properties, false);
          

            _MaskUVSpeedAndRota = FindProperty("_MaskUVSpeedAndRota", properties, false);
            _PannerUVSpeedAndRota = FindProperty("_PannerUVSpeedAndRota", properties, false);
            _DissloveUVSpeedAndRota = FindProperty("_DissloveUVSpeedAndRota", properties, false);

            _MainUOffset = FindProperty("_Main_U_Offset", properties, false);
            _MainVOffset = FindProperty("_Main_V_Offset", properties, false);

            _Hardness = FindProperty("_Hardness", properties, false);
            _Edgewidth = FindProperty("_Edgewidth", properties, false);
            _EdgeColor = FindProperty("_EdgeColor", properties, false);
            _BaseColor = FindProperty("_Color", properties, false);
            _Fresnel = FindProperty(Prop._Frenesl, properties, false);
            _FresnelColor = FindProperty("_FresnelColor", properties, false);
            _FresnelWidth = FindProperty("_FresnelWidth", properties, false);
            _FresnelIntensity = FindProperty("_FresnelIntensity", properties, false);
            _Mode = FindProperty("_Mode", properties, false);

            // Advanced Props
            _specHighlights = FindProperty(Prop._SpecularHighlights, properties, false);
            _reflections = FindProperty(Prop._EnvironmentReflections, properties, false);

            _queueOffsetProp = FindProperty(Prop._QueueOffset, properties, false);
            _MaterialModeProp = FindProperty(Prop._MaterialMode, properties, false);
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
            DrawMaterialName(material);
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

        public virtual void DrawMaterialName(Material mat) {
            if (_MaterialModeProp == null) return;
            EditorGUI.BeginChangeCheck();
            var add=DoPopup(new GUIContent("MaterialMode"), _MaterialModeProp, new[] { "Add", "Blend" });
           // var AddText = Styles.ADDOrBLENDText(add == 0);
         
            EditorGUILayout.Space(8);
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material)obj);
            }
        }

        public virtual void OnOpenGUI(Material material, MaterialEditor _materialEditor) {
            // Foldout states
            m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
            m_SurfaceOptionsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceOptionsFoldout", true);
            m_SurfaceInputsFoldout = new SavedBool($"{m_HeaderStateKey}.SurfaceInputsFoldout", true);
            m_AdvancedFoldout = new SavedBool($"{m_HeaderStateKey}.AdvancedFoldout", false);

            foreach (var obj in _materialEditor.targets)
                
                MaterialChanged((Material)obj);
        }

        public void ShaderPropertiesGUI(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            EditorGUI.BeginChangeCheck();
            m_SurfaceOptionsFoldout.value =
              EditorGUILayout.BeginFoldoutHeaderGroup(m_SurfaceOptionsFoldout.value, Styles.SurfaceOptions);
            if (m_SurfaceOptionsFoldout.value)
            {
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
            if (m_AdvancedFoldout.value)
            {
                DrawAdvancedOptions(material);
                EditorGUILayout.Space();
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
            //    DrawAdditionalFoldouts(material);

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

            DrawCullingProp(material);

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

            DoPopup(Styles.ModeType, _Mode, Enum.GetNames(typeof(ModeType)), 0);

            DoFloatField(_Extrusion, 0);
            if (baseMapProp != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                if (_baseColorProp != null)
                {
                //    _materialEditor.TexturePropertySingleLine(Styles.baseMap, baseMapProp);
                //}
                //else
                //{
                    _materialEditor.TexturePropertySingleLine(Styles.baseMap, baseMapProp, _baseColorProp);
                }
          
                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(Prop._BaseMap))
                {
                    material.SetTexture(Prop._BaseMap, baseMapProp.textureValue);
                    var baseMapTiling = baseMapProp.textureScaleAndOffset;
                    material.SetTextureScale(Prop._BaseMap, new Vector2(baseMapTiling.x, baseMapTiling.y));
                    material.SetTextureOffset(Prop._BaseMap, new Vector2(baseMapTiling.z, baseMapTiling.w));
                    //material.SetTextureOffset(_MainUVOffset, new Vector2());
                }
               // DoColorField(_BaseColor, 0 , true, true, true);
               // EditorGUILayout.EndHorizontal();
            }
            DrawTileOffset(_materialEditor, baseMapProp);

            _materialEditor.VectorProperty(_MainUVSpeedAndRota, "MainUVSpeed(uv)  Rota(z)");
            
           // _materialEditor.VectorProperty(_MainUVOffset, "Main_U_Offset(x) Main_V_Offset(y)");
            //DrawBaseMapProperties(material);
            EditorGUILayout.BeginHorizontal();
            DoFloatField(_MainUOffset,0);
            DoFloatField(_MainVOffset,2);
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.Space(8);
            DrawMaskProperties(material);
            DrawTileOffset(_materialEditor, maskMapProp);
            _materialEditor.VectorProperty(_MaskUVSpeedAndRota, "MaskUVSpeed(uv)  Rota(z) MaskIntensity(w)");
            EditorGUILayout.Space(8);
            DrawPannerProperties(material);
            DrawTileOffset(_materialEditor, pannerMapProp);
            _materialEditor.VectorProperty(_PannerUVSpeedAndRota, "PannerUVSpeed(uv)  Rota(z) PannerIntensity(w)");
            EditorGUILayout.Space(8);
            DrawDissloveProperties(material);
            DrawTileOffset(_materialEditor, dissloveMapProp);
            _materialEditor.VectorProperty(_DissloveUVSpeedAndRota, "DissloveUVSpeed(uv) Rota(z) DissloveIntensity(w)");

            DoFloatField(_Hardness, 0);
            EditorGUILayout.BeginHorizontal();
            DoFloatField(_Edgewidth, 0);
            DoColorField(_EdgeColor, 5, true, true, true);
            EditorGUILayout.EndHorizontal();

            DoToggleField(_Fresnel, Styles.Fresnel);

            EditorGUILayout.BeginHorizontal();
            DoFloatField(_FresnelWidth, 0);
            DoColorField(_FresnelColor, 5, true, true, true);
            EditorGUILayout.EndHorizontal();
            DoFloatField(_FresnelIntensity, 0);
           
          

            if (EditorGUI.EndChangeCheck())
            {
                MaterialChanged(material);
            }
        }

        public virtual void DrawAdvancedOptions(Material material)
        {
            //    _materialEditor.EnableInstancingField();
            //    if (_reflections != null && _specHighlights != null) {
            //        EditorGUI.BeginChangeCheck();
            //        _materialEditor.ShaderProperty(_specHighlights, Styles.highlightsText);
            //        _materialEditor.ShaderProperty(_reflections, Styles.reflectionsText);
            //        if (EditorGUI.EndChangeCheck()) {
            //            MaterialChanged(material);
            //        }
            //    } else {
            //        if (_specHighlights != null) {
            //            EditorGUI.BeginChangeCheck();
            //            _materialEditor.ShaderProperty(_specHighlights, Styles.highlightsText);
            //            if (EditorGUI.EndChangeCheck()) {
            //                MaterialChanged(material);
            //            }
            //        }
            //    }

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

        public virtual void DrawParasProperties(Material material)
        {

        }
        public virtual void DrawBaseMapProperties(Material material)
        {
            if (baseMapProp != null && _baseColorProp != null) // Draw the baseMap, most shader will have at least a baseMap
            {
                _materialEditor.TexturePropertySingleLine(Styles.baseMap, baseMapProp, _baseColorProp);
                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(Prop._BaseMap))
                {
                    material.SetTexture(Prop._BaseMap, baseMapProp.textureValue);
                    var baseMapTiling = baseMapProp.textureScaleAndOffset;
                    material.SetTextureScale(Prop._BaseMap, new Vector2(baseMapTiling.x, baseMapTiling.y));
                    material.SetTextureOffset(Prop._BaseMap, new Vector2(baseMapTiling.z, baseMapTiling.w));
                    _materialEditor.VectorProperty(_MainUVSpeedAndRota, "MainUVSpeed(uv)  Rota(z)");
                }
            }
        }

        protected virtual void DrawMaskProperties(Material material)
        {
            if (maskMapProp != null)
            {
                _materialEditor.TexturePropertySingleLine(Styles.maskMap, maskMapProp);
                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(Prop._MaskMap))
                {
                    material.SetTexture(Prop._MaskMap, maskMapProp.textureValue);
                    var maskMapTiling = maskMapProp.textureScaleAndOffset;
                   // material.SetVector(Prop._MaskMap, new Vector4(maskMapTiling.x, maskMapTiling.y, maskMapTiling.z, maskMapTiling.w));
                    material.SetTextureScale(Prop._MaskMap, new Vector2(maskMapTiling.x, maskMapTiling.y));
                    material.SetTextureOffset(Prop._MaskMap, new Vector2(maskMapTiling.z, maskMapTiling.w));

                }
            }
        }
        protected virtual void DrawPannerProperties(Material material)
        {
            if (pannerMapProp != null)
            {
                _materialEditor.TexturePropertySingleLine(Styles.pannerMap, pannerMapProp);
                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(Prop._PannerTex))
                {
                    material.SetTexture(Prop._PannerTex, pannerMapProp.textureValue);
                    var pannerMapTiling = pannerMapProp.textureScaleAndOffset;
                   // material.SetVector(Prop._PannerTex, new Vector4(pannerMapTiling.x, pannerMapTiling.y, pannerMapTiling.z, pannerMapTiling.w));
                    material.SetTextureScale(Prop._PannerTex, new Vector2(pannerMapTiling.x, pannerMapTiling.y));
                    material.SetTextureOffset(Prop._PannerTex, new Vector2(pannerMapTiling.z, pannerMapTiling.w));


                }
            }
        }
        protected virtual void DrawDissloveProperties(Material material)
        {
            if (dissloveMapProp != null)
            {
                _materialEditor.TexturePropertySingleLine(Styles.dissloveMap, dissloveMapProp);
                // TODO Temporary fix for lightmapping, to be replaced with attribute tag.
                if (material.HasProperty(Prop._DissloveTex))
                {
                    material.SetTexture(Prop._DissloveTex, dissloveMapProp.textureValue);
                    var dissloveMapTiling = dissloveMapProp.textureScaleAndOffset;
                    material.SetTextureScale(Prop._DissloveTex, new Vector2(dissloveMapTiling.x, dissloveMapTiling.y));
                    material.SetTextureOffset(Prop._DissloveTex, new Vector2(dissloveMapTiling.z, dissloveMapTiling.w));
               

                }
            }
        }

     
        protected static void DrawTileOffset(MaterialEditor _materialEditor, MaterialProperty textureProp) {
            _materialEditor.TextureScaleOffsetProperty(textureProp);
        }

        #endregion

        ////////////////////////////////////
        // Material Data Functions        //
        ////////////////////////////////////s

        #region MaterialDataFunctions
        public void SetMaterialKeywords(Material material, Action<Material> shadingModelFunc = null,
                                        Action<Material> shaderFunc = null)
        {
            // Clear all keywords for fresh start
            material.shaderKeywords = null;
            // Setup blending - consistent across all Universal RP shaders
            SetupMaterialBlendMode(material);
            if (material.HasProperty(Prop._Frenesl))
            {
                var state = material.GetFloat(Prop._Frenesl) == 1.0f;
                CoreUtils.SetKeyword(material, Keyword._FresnelOn, state);
            }
            if (material.HasProperty(Prop._MaterialMode))
            {
                var state = material.GetFloat(Prop._MaterialMode) == 0.0f;
                CoreUtils.SetKeyword(material, Keyword._ADDOrBLEND, state);
                //Debug.Log(state);
            }
          
            // Shader specific keyword functions
            shadingModelFunc?.Invoke(material);
            shaderFunc?.Invoke(material);
        }
   
        public static void SetupMaterialBlendMode(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            var queueOffset = 0; // queueOffsetRange;
            if (material.HasProperty(Prop._QueueOffset))
                queueOffset = queueOffsetRange - (int)material.GetFloat(Prop._QueueOffset);

                var queue = (int)RenderQueue.Transparent;
            var MaterialMode = (MaterialType)material.GetFloat(Prop._MaterialMode);
            if (MaterialMode== MaterialType.Add)
            {
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
            }
            else if (MaterialMode == MaterialType.Blend)
            {
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            }
            material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
            material.renderQueue = queue + queueOffset;
         
        }
    


        //public static void SetupMaterialBlendMode(Material material)
        //{
        //    if (material == null)
        //        throw new ArgumentNullException("material");

        //    var alphaClip = false;

        //    if (material.HasProperty(Prop._AlphaClip))
        //    {
        //        alphaClip = material.GetFloat(Prop._AlphaClip) == 1;
        //        if (alphaClip)
        //        {
        //            material.EnableKeyword(Keyword._ALPHATEST_ON);
        //        }
        //        else
        //        {
        //            material.DisableKeyword(Keyword._ALPHATEST_ON);
        //        }
        //    }

        //    var queueOffset = 0; // queueOffsetRange;
        //    if (material.HasProperty(Prop._QueueOffset))
        //        queueOffset = queueOffsetRange - (int)material.GetFloat(Prop._QueueOffset);

        //    SurfaceType surfaceType = SurfaceType.Transparent;
        //    if (material.HasProperty(Prop._Surface))
        //    {
        //        surfaceType = (SurfaceType)material.GetFloat(Prop._Surface);
        //    }

        //    if (surfaceType == SurfaceType.Opaque)
        //    {
        //        if (alphaClip)
        //        {
        //            material.renderQueue = (int)RenderQueue.AlphaTest;
        //            material.SetOverrideTag(Tag.RenderType, Tag.TransparentCutout);
        //        }
        //        else
        //        {
        //            material.renderQueue = (int)RenderQueue.Transparent;
        //            material.SetOverrideTag(Tag.RenderType, Tag.Opaque);
        //        }

        //        material.renderQueue += queueOffset;
        //        material.SetInt(Prop._SrcBlend, (int)UnityEngine.Rendering.BlendMode.One);
        //        material.SetInt(Prop._DstBlend, (int)UnityEngine.Rendering.BlendMode.Zero);
        //        material.SetInt(Prop._ZWrite, 1);
        //        material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
        //        material.SetShaderPassEnabled(Pass.ShadowCaster, true);
        //    }
        //    else
        //    {
        //        var blendMode = (BlendMode)material.GetFloat(Prop._Blend);
        //        var queue = (int)RenderQueue.Transparent;

        //        Specific Transparent Mode Settings
        //        switch (blendMode)
        //        {
        //            case BlendMode.Alpha:
        //                material.SetInt(Prop._SrcBlend, (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        //                material.SetInt(Prop._DstBlend, (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        //                material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
        //                break;
        //            case BlendMode.Premultiply:
        //                material.SetInt(Prop._SrcBlend, (int)UnityEngine.Rendering.BlendMode.One);
        //                material.SetInt(Prop._DstBlend, (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        //                material.EnableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
        //                break;
        //            case BlendMode.Additive:
        //                material.SetInt(Prop._SrcBlend, (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        //                material.SetInt(Prop._DstBlend, (int)UnityEngine.Rendering.BlendMode.One);
        //                material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
        //                break;
        //            case BlendMode.Multiply:
        //                material.SetInt(Prop._SrcBlend, (int)UnityEngine.Rendering.BlendMode.DstColor);
        //                material.SetInt(Prop._DstBlend, (int)UnityEngine.Rendering.BlendMode.Zero);
        //                material.DisableKeyword(Keyword._ALPHAPREMULTIPLY_ON);
        //                material.EnableKeyword(Keyword._ALPHAMODULATE_ON);
        //                break;
        //        }

        //        General Transparent Material Settings
        //    material.SetOverrideTag(Tag.RenderType, Tag.Transparent);
        //        material.SetInt(Prop._ZWrite, 0);
        //        material.renderQueue = queue + queueOffset;
        //        material.SetShaderPassEnabled(Pass.ShadowCaster, false);
        //    }
        //}

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
                                              MaterialEditor _materialEditor, float labelWidth = 30f) {
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
                _materialEditor.RegisterPropertyChangeUndo(title.text);
                prop1.floatValue = prop1val;
                prop2.floatValue = prop2val;
            }

            EditorGUI.showMixedValue = false;
        }

        public float DoPopup(GUIContent label, MaterialProperty property, string[] options, int indent = 1) {
            return DoPopup(label, property, options, _materialEditor, indent);
        }

        protected static float DoPopup(GUIContent label, MaterialProperty property, string[] options,
                                       MaterialEditor _materialEditor, int indent = 1) {
            if (property == null)
                throw new ArgumentNullException("property");
            EditorGUI.showMixedValue = property.hasMixedValue;
            var mode = property.floatValue;
            EditorGUI.indentLevel += indent;
            EditorGUI.BeginChangeCheck();
            mode = EditorGUILayout.Popup(label, (int) mode, options);
            if (EditorGUI.EndChangeCheck()) {
                _materialEditor.RegisterPropertyChangeUndo(label.text);
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
        protected Rect TextureColorProps(MaterialEditor _materialEditor, GUIContent label,
                                         MaterialProperty textureProp, MaterialProperty colorProp,
                                         bool hdr = false, bool hideColorIfTex = false) {
            var rect = EditorGUILayout.GetControlRect();
            if (textureProp == null) {
                return rect;
            }

            EditorGUI.showMixedValue = textureProp.hasMixedValue;
            _materialEditor.TexturePropertyMiniThumbnail(rect, textureProp, label.text, label.tooltip);
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
                    _materialEditor.RegisterPropertyChangeUndo(colorProp.displayName);
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