using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class HairShaderGUI : BaseShaderGUI {
        enum StrandDir {
            Bitangent,
            Tangent
        }

        public static GUIContent strandDirectionText =
            new GUIContent("Strand Dir", "Set Strand Direction");

        public static GUIContent enableSecSpecText =
            new GUIContent("Second Specular",
                           "If unchecked the shader will skip the secondary highlight, which makes it faster.");

        public struct HairProperties {
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

         


            public HairProperties(MaterialProperty[] properties) {
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

        HairProperties _hairProperties;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _hairProperties = new HairProperties(properties);
            _renderSideProp = FindProperty(Prop._RenderSide, properties, false);
        }


        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, SetMaterialKeywords);
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
                    var hairRender =
                        DoPopup(new GUIContent("Render Side"),
                                _renderSideProp,
                                new[] {"Front", "Both", "VFACE"});

                    if (EditorGUI.EndChangeCheck()) {
                        _materialEditor.RegisterPropertyChangeUndo(BaseShaderGUI.Styles.cullingText.text);
                        _renderSideProp.floatValue = hairRender;
                        _cullingProp.floatValue = hairRender != 0 ? 0 : 2;
                    }
                }

                material.doubleSidedGI = (RenderFace) _cullingProp.floatValue != RenderFace.Front;
                EditorGUI.showMixedValue = false;
            }
        }
    
        public override void DrawSurfaceInputs(Material material) {
            EditorGUILayout.HelpBox("ME_MAP: Occlusion(R if use cutout) Shift(G), Emission Mask(B), Emission Noise(A)",
                                    MessageType.Warning);
            base.DrawSurfaceInputs(material);

            DrawGradientArea(material);

            if (material.HasProperty(Prop._Material_Quality) && material.GetFloat(Prop._Material_Quality) == 0) {
                DoHairArea(_hairProperties, _materialEditor, material);
            }

            if (material.HasProperty(Prop._ChangeColor)) {
                EditorGUILayout.Space(8);
                DoHeader("Change Color");
                SkinShaderGUI.DoChangeColorArea(_materialEditor, _properties);
            }

            // DrawTileOffset(_materialEditor, _baseMapProp);
        }

        public void DoHairArea(HairProperties properties, MaterialEditor materialEditor,
                               Material material) {
            EditorGUILayout.Space(8);
            GUILayout.Label("Hair Lighting", EditorStyles.boldLabel);
            DoPopup(strandDirectionText, properties.strandDirProp, new[] {"Bitangent", "Tangent"},
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
            if (properties.translucencyPowerProp == null) {
                return;
            }

            EditorGUILayout.Space(8);
            DoSliderField(properties.translucencyPowerProp, 0, 10);
            DoSliderField(properties.shadowProp, 0, 1);
            DoSliderField(properties.distortionProp, 0, 1f);
           // if (properties._EnableGradientProp == null)
           // {
           //     return;
           // }
           //var enableGradientProp= DoToggleField(properties._EnableGradientProp, "EnableGradient", 0);
           // if (enableGradientProp)
           // {
           //     DoSliderField(properties.HeightProp, 0, 2);
           //     DoSliderField(properties.MaskLerpProp, 0, 1);
           //     if (_materialEditor != null)
           //         _materialEditor.TextureProperty(properties._GradientMapProp, "Gradient Map(RGB) MaskMap(A)");
           // }
        }

       
        // material main surface inputs

        public static void SetMaterialKeywords(Material material) {
            SetChangeColorKeyword(material);

            if (material.HasProperty(Prop._RenderSide)) {
                CoreUtils.SetKeyword(material, Keyword._VFACE, material.GetFloat(Prop._RenderSide) == 2.0f);
            }

            CoreUtils.SetKeyword(material, Keyword._SCATTERING, !material.IsKeywordEnabled(Keyword._EMISSION));

            if (material.HasProperty(Prop._EnableGradient))
            {
                CoreUtils.SetKeyword(material, Keyword._ENABLEGRADIENT, material.GetFloat(Prop._EnableGradient) == 1.0f);
             
            }
        }
    }
}