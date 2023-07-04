using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class ClothShaderGUI : BaseShaderGUI {
        public static class ClothStyles {
            public static GUIContent useCottonWoolText =
                new GUIContent("Cotton Wool",
                               "Enable Charlie Sheen Lighting.");

            public static GUIContent useScatterText =
                new GUIContent("Transmission", "Enable Transmission");
        }

        public struct ClothProperties {
            // Surface Input Props
            public MaterialProperty useCottonWoolProp;
            public MaterialProperty sheenColorProp;
            public MaterialProperty anisotropyProp;

            public MaterialProperty useScatteringProp;
            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;

            public MaterialProperty shadowOffsetProp;

            public ClothProperties(MaterialProperty[] properties) {
                useCottonWoolProp = FindProperty(Prop._UseCottonWool, properties);
                sheenColorProp = FindProperty(Prop._SheenColor, properties);
                anisotropyProp = FindProperty(Prop._Anisotropy, properties);

                useScatteringProp = FindProperty(Prop._UseScattering, properties);
                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties);
                shadowProp = FindProperty(Prop._ShadowStrength, properties);
                distortionProp = FindProperty(Prop._Distortion, properties);
                shadowOffsetProp = FindProperty(Prop._ShadowOffset, properties);
            }
        }

        ClothProperties _clothProperties;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _clothProperties = new ClothProperties(properties);
        }

        public void Inputs(ClothProperties properties, MaterialEditor materialEditor, Material material) {
            if (GetQuality != HIGH_QUALITY) {
                return;
            }

            DoClothArea(properties, materialEditor);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public override void DrawSurfaceInputs(Material material) {
            base.DrawSurfaceInputs(material);
            Inputs(_clothProperties, _materialEditor, material);
            DrawTileOffset(_materialEditor, _baseMapProp);
        }

        public void DoClothArea(ClothProperties properties, MaterialEditor materialEditor) {
            DoHeader("Cloth");
            var useCottonWool = DoToggleField(properties.useCottonWoolProp, ClothStyles.useCottonWoolText, 0);
            EditorGUI.BeginDisabledGroup(!useCottonWool);
            {
                DoHeader("Charlie Sheen Lighting", 2);
                DoColorField(properties.sheenColorProp, 2);
            }

            EditorGUI.EndDisabledGroup();
            EditorGUILayout.Space(8);
            EditorGUI.BeginDisabledGroup(useCottonWool);
            {
                DoHeader("GGX anisotropic Lighting", 2);
                DoSliderField(properties.anisotropyProp, 0, 1);

                DoHeader("Transmission", 2);
                var useScattering = DoToggleField(properties.useScatteringProp, ClothStyles.useScatterText, 2);
                EditorGUI.BeginDisabledGroup(!useScattering);
                {
                    DoSliderField(properties.translucencyPowerProp, 0, 10, 3);
                    DoSliderField(properties.shadowProp, 0, 1, 3);
                    DoSliderField(properties.distortionProp, 0, 1, 3);
                }
                EditorGUI.EndDisabledGroup();
            }
            EditorGUI.EndDisabledGroup();

            EditorGUILayout.Space(8);
            DoFloatField(properties.shadowOffsetProp);
        }


        // material main surface inputs
        public void SetMaterialKeywords(Material material) {
            if (GetQuality == LOW_QUALITY) {
                return;
            }

            if (material.HasProperty(Prop._UseCottonWool)) {
                var useCottonWool = material.GetFloat(Prop._UseCottonWool) == 1.0f;
                CoreUtils.SetKeyword(material, Keyword._COTTONWOOL,
                                     useCottonWool);
                if (!useCottonWool && !material.IsKeywordEnabled(Keyword._NORMALMAP)) {
                    CoreUtils.SetKeyword(material, Keyword._NORMALMAP, true);
                }
            }


            if (material.HasProperty(Prop._UseScattering))
                CoreUtils.SetKeyword(material, Keyword._SCATTERING,
                                     material.GetFloat(Prop._UseScattering) == 1.0f);
        }
    }
}