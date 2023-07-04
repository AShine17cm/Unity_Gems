using System;
using UnityEditor;
using UnityEditor.Rendering.Universal;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class GrassShaderGUI : BaseShaderGUI {
        public struct GrassProperties {
            public MaterialProperty enableSSSProp;
            public MaterialProperty subsurfProp;
            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;

            public MaterialProperty rangeProp;
            public MaterialProperty speedProp;
            public MaterialProperty cameraDistance;
           
            public GrassProperties(MaterialProperty[] properties) {
                // Map Input Props
                enableSSSProp = FindProperty(Prop._EnableSSS, properties, false);
                subsurfProp = FindProperty(Prop._SubsurfaceColor, properties, false);
                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties, false);
                shadowProp = FindProperty(Prop._ShadowStrength, properties, false);
                distortionProp = FindProperty(Prop._Distortion, properties, false);

                rangeProp = FindProperty(Prop._Range, properties, false);
                speedProp = FindProperty(Prop._Speed, properties, false);
                cameraDistance = FindProperty(Prop._CameraDistance, properties, false);
               
            }
        }

        GrassProperties _grassProperties;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _grassProperties = new GrassProperties(properties);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public override void DrawMaterialQuality(Material mat) {
            if (!DrawFourLevelMaterialQuality(_materialEditor, _MaterialQualityProp)) return;
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material) obj);
            }
        }

        public static bool DrawFourLevelMaterialQuality(MaterialEditor materialEditor,
                                                        MaterialProperty materialQualityProp) {
            if (materialQualityProp == null) return false;
            EditorGUI.BeginChangeCheck();
            DoPopup(new GUIContent("Quality"), materialQualityProp, new[] {"Editor", "High", "Medium", "Low"},
                    materialEditor);
            EditorGUILayout.Space(8);
            return true;
        }

        public override void SetMaterialQuality(Material material) {
            SetFourLevelMaterialQuality(material);
        }

        public static void SetFourLevelMaterialQuality(Material material) {
            if (!material.HasProperty(Prop._Material_Quality)) return;
            var quality = (int) material.GetFloat(Prop._Material_Quality);
            switch (quality) {
                case 0:
                    material.shader.maximumLOD = Editor_QUALITY;
                    break;
                case 1:
                    material.shader.maximumLOD = HIGH_QUALITY;
                    break;
                case 2:
                    material.shader.maximumLOD = MEDIUM_QUALITY;
                    break;
                case 3:
                    material.shader.maximumLOD = LOW_QUALITY;
                    break;
            }
        }


        public override void DrawBaseProperties(Material material) {
            base.DrawBaseProperties(material);
            var enableSSS = DoToggleField(_grassProperties.enableSSSProp, new GUIContent("SSS"), 0);
            if (enableSSS) {
                DoColorField(_grassProperties.subsurfProp);
                DoSliderField(_grassProperties.translucencyPowerProp, 0, 10);
                DoSliderField(_grassProperties.shadowProp, 0, 10);
                DoSliderField(_grassProperties.distortionProp, 0, 1f);
            }

            EditorGUILayout.Space(8);
            DoFloatField(_grassProperties.rangeProp);
            DoFloatField(_grassProperties.speedProp);
            DoFloatField(_grassProperties.cameraDistance);
         
            EditorGUILayout.Space(8);
        }

        public static void SetMaterialKeywords(Material material) {
            if (material.HasProperty(Prop._EnableSSS)) {
                var mode = material.GetFloat(Prop._EnableSSS);
                CoreUtils.SetKeyword(material, Keyword._SCATTERING, mode == 1.0f);
            }
         
        }
    }
}