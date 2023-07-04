using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class UniversalLitShaderGUI : BaseShaderGUI {
        public static readonly string[] colorModeNames = { "None", "SoftLight" };
        public static GUIContent colorModeText =
          new GUIContent("Color Mode", "Change Color.");

        enum ShaderType
        {
            Lit,
            Skin,
            Hair
        }
        public static class SkinStyles
        {
            public static GUIContent lutMapText =
                new GUIContent("LUT Map", "Add lighting");

            public static GUIContent applyNormalDiffuseText =
                new GUIContent("Normal Diff",
                               "Enable Diffuse Normal Sample.");
        }
        enum StrandDir
        {
            Bitangent,
            Tangent
        }

        public static GUIContent strandDirectionText =
            new GUIContent("Strand Dir", "Set Strand Direction");

        public static GUIContent enableSecSpecText =
            new GUIContent("Second Specular",
                           "If unchecked the shader will skip the secondary highlight, which makes it faster.");
        public struct SkinLitProperties
        {
            public MaterialProperty lutMapProp;
            public MaterialProperty lightPowerProp;
            public MaterialProperty subsurfProp;
            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;
            public MaterialProperty readProp;
            public MaterialProperty enableSkin;
            public MaterialProperty addSkinProp;

            public SkinLitProperties(MaterialProperty[] properties)
            {
                // Map Input Props
                lutMapProp = FindProperty(Prop._LUTMap, properties, false);
                lightPowerProp = FindProperty(Prop._lightPower, properties, false);
                enableSkin = FindProperty(Prop._EnableSkin, properties, false);
                addSkinProp = FindProperty(Prop._addSkinColor, properties, false);
                subsurfProp = FindProperty(Prop._SubsurfaceColor, properties, false);
                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties, false);
                shadowProp = FindProperty(Prop._ShadowStrength, properties, false);
                distortionProp = FindProperty(Prop._Distortion, properties, false);
                readProp = FindProperty(Prop._ReadProps, properties, false);
            }
        }

        SkinLitProperties _skinLitProperties;
        public struct HairProperties
        {
            // Surface Input Props
            public MaterialProperty strandDirProp;

            public MaterialProperty specShiftProp;
            public MaterialProperty specTiltProp;
            public MaterialProperty specExpProp;

            public MaterialProperty enableSpec2;
            public MaterialProperty spec2ShiftProp;
            public MaterialProperty spec2TiltProp;
            public MaterialProperty spec2ExpProp;

            public MaterialProperty rimTransIntensityProp;
            public MaterialProperty ambRefProp;

            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;


            public HairProperties(MaterialProperty[] properties)
            {
                // Surface Input Props
                strandDirProp = FindProperty(Prop._StrandDir, properties);

                specShiftProp = FindProperty(Prop._SpecularShift, properties);
                specTiltProp = FindProperty(Prop._SpecularTint, properties);
                specExpProp = FindProperty(Prop._SpecularExponent, properties);

                enableSpec2 = FindProperty(Prop._SecondaryLobe, properties, false);
                spec2ShiftProp = FindProperty(Prop._SecondarySpecularShift, properties, false);
                spec2TiltProp = FindProperty(Prop._SecondarySpecularTint, properties, false);
                spec2ExpProp = FindProperty(Prop._SecondarySpecularExponent, properties, false);

                rimTransIntensityProp = FindProperty(Prop._RimTransmissionIntensity, properties);
                ambRefProp = FindProperty(Prop._AmbientReflection, properties);

                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties, false);
                shadowProp = FindProperty(Prop._ShadowStrength, properties, false);
                distortionProp = FindProperty(Prop._Distortion, properties, false);



            }
        }
        public MaterialProperty _renderSideProp;
        public MaterialProperty _StencilIDProp;
        public MaterialProperty _StencilCompModeProp;
        public MaterialProperty _EnableLitProp;
        public MaterialProperty _EnableSkinProp;
        public MaterialProperty _EnableHairProp;
        protected MaterialProperty _ShaderTypeProp { get; set; }
        HairProperties _hairProperties;
        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _hairProperties = new HairProperties(properties);
            _renderSideProp = FindProperty(Prop._RenderSide, properties, false);
            _skinLitProperties = new SkinLitProperties(properties);
            _ShaderTypeProp = FindProperty(Prop._ShaderType, properties, false);
            _StencilIDProp = FindProperty(Prop._StencilID,properties,false);
            _StencilCompModeProp = FindProperty(Prop._StencilCompMode, properties, false);
            _EnableLitProp = FindProperty(Prop._EnableLit, properties, false);
            _EnableSkinProp = FindProperty(Prop._EnableSkinProp, properties, false);
            _EnableHairProp = FindProperty(Prop._EnableHair, properties, false);


        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, SetMaterialKeywords);
        }
        public void DoSkinArea(SkinLitProperties properties, MaterialEditor materialEditor)
        {
            DoTextureField(properties.lutMapProp);

            DoSliderField(properties.lightPowerProp, 1, 2);

            EditorGUILayout.Space(8);

            DoColorField(properties.subsurfProp);
            DoSliderField(properties.translucencyPowerProp, 0, 10);
            DoSliderField(properties.shadowProp, 0, 1);
            DoSliderField(properties.distortionProp, 0, 1f);
        }
        public void DoAddSkinColorArea(SkinLitProperties properties, MaterialEditor materialEditor)
        {
            if (properties.enableSkin == null)
            {
                return;
            }
            var enableSkin = DoToggleField(properties.enableSkin, new GUIContent("EnableSkin"), 0);
            if (enableSkin)
            {
                DoColorField(properties.addSkinProp);
            }

        }


        public void DoHairArea(HairProperties properties, MaterialEditor materialEditor,
                           Material material)
        {
            EditorGUILayout.Space(8);
            GUILayout.Label("Hair Lighting", EditorStyles.boldLabel);
            DoPopup(strandDirectionText, properties.strandDirProp, new[] { "Bitangent", "Tangent" },
                    materialEditor);

            EditorGUILayout.Space(8);
            DoSliderField(properties.specShiftProp, -1.0f, 1f);
            DoColorField(properties.specTiltProp, 1, true, false, true);
            DoSliderField(properties.specExpProp, 0.0f, 1f);
            EditorGUILayout.Space(8);
            var secondLob = DoToggleField(properties.enableSpec2, enableSecSpecText);
            EditorGUI.BeginDisabledGroup(!secondLob);
            {
                DoSliderField(properties.spec2ShiftProp, -1.0f, 1f, 2);
                DoColorField(properties.spec2TiltProp, 2, true, false, true);
                DoSliderField(properties.spec2ExpProp, 0.0f, 1f, 2);
            }
            EditorGUI.EndDisabledGroup();
            EditorGUILayout.Space(8);
            DoSliderField(properties.rimTransIntensityProp, 0.0f, 1f);
            DoSliderField(properties.ambRefProp, 0.0f, 1f);

            if (material.IsKeywordEnabled(Keyword._EMISSION)) return;
            if (properties.translucencyPowerProp == null)
            {
                return;
            }

            EditorGUILayout.Space(8);
            DoSliderField(properties.translucencyPowerProp, 0, 10);
            DoSliderField(properties.shadowProp, 0, 1);
            DoSliderField(properties.distortionProp, 0, 1f);

        }

        public override void DrawSurfaceOptions(Material material)
        {
          
            EditorGUI.BeginChangeCheck();
            if (material.HasProperty(Prop._EnableHair))
            {
                if (_surfaceTypeProp != null)
                {
                    DoPopup(Styles.surfaceType, _surfaceTypeProp, Enum.GetNames(typeof(SurfaceType)));
                    if ((SurfaceType)material.GetFloat(Prop._Surface) == SurfaceType.Transparent && _blendModeProp != null)
                        DoPopup(Styles.blendingMode, _blendModeProp, Enum.GetNames(typeof(BlendMode)));
                }
            }

            DrawCullingProp(material);
            if (_StencilIDProp!=null)
            {
                DoSliderField(_StencilIDProp, 0,255, 3);
            }
            if (_StencilCompModeProp != null)
            {
                DoPopup(new GUIContent("StencilCompMode"), _StencilIDProp, Enum.GetNames(typeof(UnityEngine.Rendering.CompareFunction)));
            }
            if (_receiveShadowsProp != null)
            {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _receiveShadowsProp.hasMixedValue;
                var receiveShadows =
                    EditorGUILayout.Toggle(Styles.receiveShadowText, _receiveShadowsProp.floatValue == 1.0f);
                if (EditorGUI.EndChangeCheck())
                    _receiveShadowsProp.floatValue = receiveShadows ? 1.0f : 0.0f;
                EditorGUI.showMixedValue = false;
            }

            //if (EditorGUI.EndChangeCheck())
            //{
            //    foreach (var obj in _materialEditor.targets)
            //        MaterialChanged((Material)obj);
            //}
        }
        protected override void DrawCullingProp(Material material)
        {
            if (material.HasProperty(Prop._EnableLit))
            {
                if (_cullingProp != null)
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUI.showMixedValue = _cullingProp.hasMixedValue;
                    var culling = (RenderFace)_cullingProp.floatValue;
                    culling = (RenderFace)EditorGUILayout.EnumPopup(Styles.cullingText, culling);
                    if (EditorGUI.EndChangeCheck())
                    {
                        _materialEditor.RegisterPropertyChangeUndo(Styles.cullingText.text);
                        _cullingProp.floatValue = (float)culling;
                        material.doubleSidedGI = (RenderFace)_cullingProp.floatValue != RenderFace.Front;
                    }

                    EditorGUI.showMixedValue = false;
                }
            }
            if (material.HasProperty(Prop._EnableHair))
            {
                if (_cullingProp != null)
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUI.showMixedValue = _cullingProp.hasMixedValue;
                    if (_renderSideProp == null)
                    {
                        var culling = (RenderFace)_cullingProp.floatValue;
                        culling = (RenderFace)EditorGUILayout.EnumPopup(BaseShaderGUI.Styles.cullingText, culling);
                        if (EditorGUI.EndChangeCheck())
                        {
                            _materialEditor.RegisterPropertyChangeUndo(BaseShaderGUI.Styles.cullingText.text);
                            _cullingProp.floatValue = (float)culling;
                        }
                    }
                    else
                    {
                        var hairRender =
                            DoPopup(new GUIContent("Render Side"),
                                    _renderSideProp,
                                    new[] { "Front", "Both", "VFACE" });

                        if (EditorGUI.EndChangeCheck())
                        {
                            _materialEditor.RegisterPropertyChangeUndo(BaseShaderGUI.Styles.cullingText.text);
                            _renderSideProp.floatValue = hairRender;
                            _cullingProp.floatValue = hairRender != 0 ? 0 : 2;
                        }
                    }

                    material.doubleSidedGI = (RenderFace)_cullingProp.floatValue != RenderFace.Front;
                    EditorGUI.showMixedValue = false;
                }
                if (_alphaClipProp != null && _alphaCutoffProp != null)
                {
                    EditorGUI.BeginChangeCheck();
                    EditorGUI.showMixedValue = _alphaClipProp.hasMixedValue;
                    var alphaClipEnabled = EditorGUILayout.Toggle(Styles.alphaClipText, _alphaClipProp.floatValue == 1);
                    if (EditorGUI.EndChangeCheck())
                        _alphaClipProp.floatValue = alphaClipEnabled ? 1 : 0;
                    EditorGUI.showMixedValue = false;

                    if (_alphaClipProp.floatValue == 1)
                        _materialEditor.ShaderProperty(_alphaCutoffProp, Styles.alphaClipThresholdText, 1);
                }
            }


        }
        public static void DoChangeColorArea(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            var changeModeProp = FindProperty(Prop._ColorMode, properties, false);
            var changeColorProp = FindProperty(Prop._ChangeColor, properties, false);
            if (changeModeProp != null && changeColorProp != null)
            {
                var mode = DoPopup(colorModeText, changeModeProp, colorModeNames, materialEditor);
                EditorGUI.BeginDisabledGroup(mode == 0);
                {
                    DoColorField(changeColorProp, 2);
                }
                EditorGUI.EndDisabledGroup();
            }
            else if (changeColorProp != null)
            {
                DoColorField(changeColorProp, 2, true, true);
            }
        }
        public override void DrawBaseProperties(Material material) {
            DrawNSArea(material);
            DrawEmissionArea();
            EditorGUILayout.Space(8);

            var enablelitProp = DoToggleField(_EnableLitProp, "EnableLit", 0);
            if (enablelitProp)
            {
                DrawPatternProp();
                if (GetQuality == 1)
                {
                    DrawSpecColor(material);
                }
            }

            var enableSkinProp = DoToggleField(_EnableSkinProp, "EnableSkin", 0);
            if (enableSkinProp)
            {
                DrawEnableMaskMap();
                EditorGUILayout.Space(8);
                EditorGUI.BeginDisabledGroup(material.HasProperty(Prop._ReadProps));
                DrawSpecColor(material);
                EditorGUI.EndDisabledGroup();

                DoChangeColorArea(_materialEditor, _properties);
                DoAddSkinColorArea(_skinLitProperties, _materialEditor);
                if (material.HasProperty(Prop._Material_Quality) && material.GetFloat(Prop._Material_Quality) == 0)
                    DoSkinArea(_skinLitProperties, _materialEditor);

                EditorGUILayout.Space(8);
                DoToggleField(_skinLitProperties.readProp,
                              new GUIContent("Read Global Settings", "Will Auto Set To True After Saving"));
            }
            var enableHairProp = DoToggleField(_EnableHairProp, "EnableHair", 0);
            if (enableHairProp)
            {
                DrawSpecColor(material);
                DrawGradientArea(material);

                if (material.HasProperty(Prop._Material_Quality) && material.GetFloat(Prop._Material_Quality) == 0)
                {
                    DoHairArea(_hairProperties, _materialEditor, material);
                }
            }
            //lit
            //if (_ShaderTypeProp!=null)
            //{
            //    DoPopup((new GUIContent("Shader Type")), _ShaderTypeProp,Enum.GetNames(typeof(ShaderType)));
            //    if((ShaderType)material.GetFloat(Prop._ShaderType) == ShaderType.Lit)
            //    {
            //        DrawPatternProp();
            //        if (GetQuality == 1)
            //        {
            //            DrawSpecColor(material);
            //        }
            //    }
            //    if ( (ShaderType)material.GetFloat(Prop._ShaderType) == ShaderType.Hair)
            //    {
            //        DrawGradientArea(material);

            //        //   DrawEnableStippleTransparencyMap();
            //        //  DrawRimArea();
            //        if (material.HasProperty(Prop._Material_Quality) && material.GetFloat(Prop._Material_Quality) == 0)
            //        {
            //            DoHairArea(_hairProperties, _materialEditor, material);
            //        }
            //    }
            //    if ((ShaderType)material.GetFloat(Prop._ShaderType) == ShaderType.Skin)
            //    {
            //        DrawEnableMaskMap();
            //        EditorGUILayout.Space(8);
            //        EditorGUI.BeginDisabledGroup(material.HasProperty(Prop._ReadProps));
            //        DrawSpecColor(material);
            //        EditorGUI.EndDisabledGroup();
            //      DoToggleField(_enableMaskMap, Styles.maskMapText, 2);
            //        DoChangeColorArea(_materialEditor, _properties);
            //        DoAddSkinColorArea(_skinLitProperties, _materialEditor);
            //        if (material.HasProperty(Prop._Material_Quality) && material.GetFloat(Prop._Material_Quality) == 0)
            //            DoSkinArea(_skinLitProperties, _materialEditor);

            //        EditorGUILayout.Space(8);
            //        DoToggleField(_skinLitProperties.readProp,
            //                      new GUIContent("Read Global Settings", "Will Auto Set To True After Saving"));
            //        EditorGUILayout.Space(8);
        
           }
         


        

    public static void SetMaterialKeywords(Material material)
    {

        if (material.HasProperty(Prop._EnableLit))
        {
            CoreUtils.SetKeyword(material, Keyword._ENABLE_LIT, material.GetFloat(Prop._EnableLit) == 1.0f);
            material.SetInt(Prop._ZWrite, 1);
            material.SetInt(Prop._Blend, 0);

        }
        if (material.HasProperty(Prop._EnableHair))
        {
            CoreUtils.SetKeyword(material, Keyword._ENABLE_HAIR, material.GetFloat(Prop._EnableHair) == 1.0f);
            if (material.HasProperty(Prop._RenderSide))
            {
                CoreUtils.SetKeyword(material, Keyword._VFACE, material.GetFloat(Prop._RenderSide) == 2.0f);
            }

            CoreUtils.SetKeyword(material, Keyword._SCATTERING, !material.IsKeywordEnabled(Keyword._EMISSION));

            if (material.HasProperty(Prop._EnableGradient))
            {
                CoreUtils.SetKeyword(material, Keyword._ENABLEGRADIENT, material.GetFloat(Prop._EnableGradient) == 1.0f);

            }
        }
        if (material.HasProperty(Prop._EnableSkinProp))
        {
             
            CoreUtils.SetKeyword(material, Keyword._ENABLE_SKIN, material.GetFloat(Prop._EnableSkinProp) == 1.0f);
            if (material.HasProperty(Prop._EnableMaskMap))
            {
                CoreUtils.SetKeyword(material, Keyword._MASKMAP, material.GetFloat(Prop._EnableMaskMap) == 1);
            }
            SetChangeColorKeyword(material);
            if (material.HasProperty(Prop._ReadProps))
            {
                CoreUtils.SetKeyword(material, Keyword._READ_PROPS,
                                     material.GetFloat(Prop._ReadProps) == 1
                                    );
            }
            material.SetInt(Prop._ZWrite, 1);
            material.SetInt(Prop._Cull, 2);
            material.SetInt(Prop._Blend, 0);

        }


    

        }

    }
}