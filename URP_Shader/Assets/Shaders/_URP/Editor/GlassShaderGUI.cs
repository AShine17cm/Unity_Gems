using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class GlassShaderGUI : BaseShaderGUI {
        MaterialProperty _EnableOpaqueTextureProp;
        MaterialProperty _CubemapProp;
        MaterialProperty _DistortionProp;
        MaterialProperty _RefractAmountProp;

        GUIContent _RefractionAmountGUI =>
            new GUIContent("Refract Amount",
                           "0: Only contains the reflection effect; \n1: Only contains the refraction effect.");

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _EnableOpaqueTextureProp = FindProperty(Prop._EnableOpaqueTexture, properties);
            _CubemapProp = FindProperty(Prop._Cubemap, properties);
            _DistortionProp = FindProperty(Prop._Distortion, properties);
            _RefractAmountProp = FindProperty(Prop._RefractAmount, properties);
        }

        public override void DrawMaterialQuality(Material mat) {
            if (!SimpleLitShaderGUI.DrawTwoLevelMaterialQuality(_materialEditor, _MaterialQualityProp)) return;
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material) obj);
            }
        }


        public override void SetMaterialQuality(Material material) {
            SimpleLitShaderGUI.SetTwoLevelMaterialQuality(material);
        }

        public override void DrawBaseProperties(Material material) {
            base.DrawBaseProperties(material);
            DoHeader("Reflection", 0);
            DoTextureField(_CubemapProp);
            DoHeader("Refraction", 0);
            var refr = DoToggleField(_EnableOpaqueTextureProp, "Enable Opaque Texture", 0);
            if (refr) {
                DoSliderField(_DistortionProp, 0, 100);
                DoSliderField(_RefractAmountProp, _RefractionAmountGUI, 0, 1);
            }

            EditorGUILayout.Space(8);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public static void SetMaterialKeywords(Material material) {
            if (material.HasProperty(Prop._EnableOpaqueTexture)) {
                var enableOpaqueTest = material.GetFloat(Prop._EnableOpaqueTexture) == 1.0f;
                CoreUtils.SetKeyword(material, Keyword._OPAQUETEX,
                                     enableOpaqueTest);
                if (enableOpaqueTest) {
                    material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.One);
                    material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt(Prop._ZWrite, 1);
                    // material.SetShaderPassEnabled(Pass.ShadowCaster, true);
                } else {
                    material.SetInt(Prop._SrcBlend, (int) UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt(Prop._DstBlend, (int) UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetOverrideTag(Tag.RenderType, Tag.Transparent);
                    material.SetInt(Prop._ZWrite, 0);
                    // material.SetShaderPassEnabled(Pass.ShadowCaster, false);
                }

                material.renderQueue += material.HasProperty(Prop._QueueOffset)
                                            ? (int) material.GetFloat(Prop._QueueOffset)
                                            : 0;
                material.renderQueue = (int)RenderQueue.Transparent;

            }
        }
    }
}