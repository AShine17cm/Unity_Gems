using System;
using UnityEditor;
using UnityEditor.Rendering.Universal;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class TreeShaderGUI : BaseShaderGUI {
        public struct TreeProperties {
            public MaterialProperty enablePivotAOProp;
            public MaterialProperty paramsProp;
            public MaterialProperty enableUVAnimProp;
            public MaterialProperty maskMapProp;
            public MaterialProperty speedProp;
            public MaterialProperty amplitudeProp;
            public MaterialProperty enableSSSProp;
            public MaterialProperty subsurfProp;
            public MaterialProperty translucencyPowerProp;
            public MaterialProperty shadowProp;
            public MaterialProperty distortionProp;
            public GUIContent AmplitudeContent => GetGuiContent(amplitudeProp, "Amplitude");
            public GUIContent ParamsContent => GetGuiContent(paramsProp, "Params");

            public TreeProperties(MaterialProperty[] properties) {
                enablePivotAOProp = FindProperty(Prop._EnablePivotAO, properties, false);
                paramsProp = FindProperty(Prop._Params, properties, false);
                enableUVAnimProp = FindProperty(Prop._EnableUVAnim, properties, false);
                speedProp = FindProperty(Prop._Speed, properties, false);
                amplitudeProp = FindProperty(Prop._Amplitude, properties, false);
                maskMapProp = FindProperty(Prop._MaskMap, properties, false);
                enableSSSProp = FindProperty(Prop._EnableSSS, properties);
                subsurfProp = FindProperty(Prop._SubsurfaceColor, properties);
                translucencyPowerProp = FindProperty(Prop._TranslucencyPower, properties);
                shadowProp = FindProperty(Prop._ShadowStrength, properties);
                distortionProp = FindProperty(Prop._Distortion, properties);
            }
        }

        public MaterialProperty _renderSideProp;
        TreeProperties _treeProperties;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _treeProperties = new TreeProperties(properties);
            _renderSideProp = FindProperty(Prop._RenderSide, properties, false);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public override void DrawBaseProperties(Material material) {
            base.DrawBaseProperties(material);
            var enablePivotAO = DoToggleField(_treeProperties.enablePivotAOProp, "Pivot AO", 0);
            if (enablePivotAO) {
                EditorGUILayout.HelpBox(_treeProperties.ParamsContent.tooltip, MessageType.Info);
                DoVectorField(_treeProperties.paramsProp, _treeProperties.ParamsContent, 1);
            }

            var enableUVAnim = DoToggleField(_treeProperties.enableUVAnimProp, "UV Anim", 0);
            if (enableUVAnim) {
                DoTextureField(_treeProperties.maskMapProp, "Mask", 1);
                DoVectorField(_treeProperties.speedProp, "Speed", 1);
                EditorGUILayout.HelpBox(_treeProperties.AmplitudeContent.tooltip, MessageType.Info);
                DoVectorField(_treeProperties.amplitudeProp, _treeProperties.AmplitudeContent, 1);
            }

            var enableSSS = DoToggleField(_treeProperties.enableSSSProp, "SSS", 0);
            if (enableSSS) {
                DoColorField(_treeProperties.subsurfProp);
                DoSliderField(_treeProperties.translucencyPowerProp, 0, 10);
                DoSliderField(_treeProperties.shadowProp, 0, 10);
                DoSliderField(_treeProperties.distortionProp, 0, 1f);
            }

            EditorGUILayout.Space(8);
        }

        protected override void DrawCullingProp(Material material) {
            if (_cullingProp != null) {
                EditorGUI.BeginChangeCheck();
                EditorGUI.showMixedValue = _cullingProp.hasMixedValue;
                if (_renderSideProp == null) {
                    var culling = (RenderFace) _cullingProp.floatValue;
                    culling = (RenderFace) EditorGUILayout.EnumPopup(BaseShaderGUI.Styles.cullingText, culling);
                    if (EditorGUI.EndChangeCheck()) {
                        _materialEditor.RegisterPropertyChangeUndo(BaseShaderGUI.Styles.cullingText.text);
                        _cullingProp.floatValue = (float) culling;
                    }
                } else {
                    var renderSide =
                        DoPopup(new GUIContent("Render Side"),
                                _renderSideProp,
                                new[] {"Front", "Back", "Both", "VFACE"});

                    if (EditorGUI.EndChangeCheck()) {
                        _materialEditor.RegisterPropertyChangeUndo(BaseShaderGUI.Styles.cullingText.text);
                        _renderSideProp.floatValue = renderSide;
                        _cullingProp.floatValue = renderSide < 2 ? (renderSide == 0 ? 2 : 1) : 0;
                    }
                }

                material.doubleSidedGI = (RenderFace) _cullingProp.floatValue != RenderFace.Front;
                EditorGUI.showMixedValue = false;
            }
        }

        public static void SetMaterialKeywords(Material material) {
            if (material.HasProperty(Prop._EnablePivotAO)) {
                CoreUtils.SetKeyword(material, Keyword._NEED_POS_OS, material.GetFloat(Prop._EnablePivotAO) == 1.0f);
            }

            if (material.HasProperty(Prop._EnableUVAnim)) {
                CoreUtils.SetKeyword(material, Keyword._MASKMAP, material.GetFloat(Prop._EnableUVAnim) == 1.0f);
            }

            if (material.HasProperty(Prop._EnableSSS)) {
                CoreUtils.SetKeyword(material, Keyword._SCATTERING, material.GetFloat(Prop._EnableSSS) == 1.0f);
            }

            if (material.HasProperty(Prop._RenderSide)) {
                CoreUtils.SetKeyword(material, Keyword._VFACE, material.GetFloat(Prop._RenderSide) > 2f);
            }
        }
    }
}