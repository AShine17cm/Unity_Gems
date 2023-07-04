using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class SimpleLitShaderGUI : BaseShaderGUI {
        MaterialProperty _baseMapAlphaAsSmoothnessProp;
        MaterialProperty _MatcapProp;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _MatcapProp = FindProperty(Prop._MatcapMap, properties, false);
            _baseMapAlphaAsSmoothnessProp = FindProperty(Prop._BaseMapAlphaAsSmoothness, properties, false);
        }


        public override void DrawMaterialQuality(Material mat) {
            if (!DrawTwoLevelMaterialQuality(_materialEditor, _MaterialQualityProp)) return;
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material) obj);
            }
        }

        public static bool DrawTwoLevelMaterialQuality(MaterialEditor materialEditor,
                                                       MaterialProperty materialQualityProp) {
            if (materialQualityProp == null) return false;
            EditorGUI.BeginChangeCheck();
            DoPopup(new GUIContent("Quality"), materialQualityProp, new[] {"Medium", "Low"}, materialEditor);
            EditorGUILayout.Space(8);
            return true;
        }

        public override void SetMaterialQuality(Material material) {
            SetTwoLevelMaterialQuality(material);
        }

        public static void SetTwoLevelMaterialQuality(Material material) {
            if (!material.HasProperty(Prop._Material_Quality)) return;
            var quality = (int) material.GetFloat(Prop._Material_Quality);
            switch (quality) {
                case 0:
                    material.shader.maximumLOD = MEDIUM_QUALITY;
                    break;
                case 1:
                    material.shader.maximumLOD = LOW_QUALITY;
                    break;
            }
        }

        public override void DrawBaseProperties(Material material) {
            base.DrawBaseProperties(material);
            if (!material.HasProperty(Prop._NSMap) || !material.GetTexture(Prop._NSMap)) {
                DoToggleField(_baseMapAlphaAsSmoothnessProp,
                              new GUIContent("Use BaseMapAlpha as Smoothness", "Only Show When not using NS Map"));
            }

            DoTextureField(_MatcapProp, "Matcap");
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, SetMaterialKeywords);
        }


        public static void SetMaterialKeywords(Material material) {
            SetChangeColorKeyword(material);
        }
    }
}