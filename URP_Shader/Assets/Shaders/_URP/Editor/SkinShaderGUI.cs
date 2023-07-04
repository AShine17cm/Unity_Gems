using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class SkinShaderGUI : BaseShaderGUI {
        public static readonly string[] colorModeNames = {"None", "SoftLight"};

        public static GUIContent colorModeText =
            new GUIContent("Color Mode", "Change Color.");

        public static class SkinStyles {
            public static GUIContent lutMapText =
                new GUIContent("LUT Map", "Add lighting");

            public static GUIContent applyNormalDiffuseText =
                new GUIContent("Normal Diff",
                               "Enable Diffuse Normal Sample.");
        }

        public struct SkinLitProperties {
            public MaterialProperty lutMapProp;
            public MaterialProperty lightPowerProp;
            public MaterialProperty subsurfProp;
            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;
            public MaterialProperty readProp;
            public MaterialProperty enableSkin;
            public MaterialProperty addSkinProp;

            public SkinLitProperties(MaterialProperty[] properties) {
                // Map Input Props
                lutMapProp = FindProperty(Prop._LUTMap, properties, false);
                lightPowerProp = FindProperty(Prop._lightPower, properties, false);
                enableSkin = FindProperty(Prop._EnableSkin,properties,false);
                addSkinProp = FindProperty(Prop._addSkinColor, properties, false);
                subsurfProp = FindProperty(Prop._SubsurfaceColor, properties, false);
                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties, false);
                shadowProp = FindProperty(Prop._ShadowStrength, properties, false);
                distortionProp = FindProperty(Prop._Distortion, properties, false);
                readProp = FindProperty(Prop._ReadProps, properties, false);
            }
        }

        SkinLitProperties _skinLitProperties;

        public override void DrawBaseProperties(Material material) {
            DrawEnableMaskMap();
            EditorGUILayout.Space(8);
            DrawNSArea(material);
            DrawEmissionArea();
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

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _skinLitProperties = new SkinLitProperties(properties);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public void DoSkinArea(SkinLitProperties properties, MaterialEditor materialEditor) {
            DoTextureField(properties.lutMapProp);

            DoSliderField(properties.lightPowerProp,1,2);
           
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
            var enableSkin = DoToggleField(properties.enableSkin,new GUIContent("EnableSkin"),0);
            if (enableSkin)
            {
                DoColorField(properties.addSkinProp);
            }
           
        }
        // material main surface inputs
        public static void SetMaterialKeywords(Material material) {
            SetChangeColorKeyword(material);

            if (material.HasProperty(Prop._ReadProps)) {
                CoreUtils.SetKeyword(material, Keyword._READ_PROPS,
                                     material.GetFloat(Prop._ReadProps) == 1
                                    );
            }
        }

        public static void DoChangeColorArea(MaterialEditor materialEditor, MaterialProperty[] properties) {
            var changeModeProp = FindProperty(Prop._ColorMode, properties, false);
            var changeColorProp = FindProperty(Prop._ChangeColor, properties, false);
            if (changeModeProp != null && changeColorProp != null) {
                var mode = DoPopup(colorModeText, changeModeProp, colorModeNames, materialEditor);
                EditorGUI.BeginDisabledGroup(mode == 0);
                {
                    DoColorField(changeColorProp, 2);
                }
                EditorGUI.EndDisabledGroup();
            } else if (changeColorProp != null) {
                DoColorField(changeColorProp, 2, true, true);
            }
        }
    }
}