using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class RockShaderGUI : BaseShaderGUI {
        public MaterialProperty enableTriplanarProp;
        public MaterialProperty textureSizeProp;

        public MaterialProperty enableMossProp;
        public MaterialProperty mossMap;
        public MaterialProperty mossScaleProp;
        public MaterialProperty mossSmoothnessProp;
        public MaterialProperty mossHeightBlendProp;
        public MaterialProperty mossBlendDistanceProp;
        public MaterialProperty mossAngleProp;

        public MaterialProperty enableIntersectionProp;
        public MaterialProperty debugToggleProp;
        public MaterialProperty valueRemapProp;
        public MaterialProperty enableVOffsetProp;
        public MaterialProperty vertexOffsetProp;
        public MaterialProperty shadowOffsetProp;
        public MaterialProperty enableShadowOffsetProp;
        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            enableTriplanarProp = FindProperty(Prop._EnableTriplanar, properties, false);
            textureSizeProp = FindProperty(Prop._TextureSize, properties, false);

            enableMossProp = FindProperty(Prop._EnableMoss, properties);
            mossScaleProp = FindProperty(Prop._MossScale, properties);
            mossSmoothnessProp = FindProperty(Prop._MossSmoothness, properties);
            mossHeightBlendProp = FindProperty(Prop._HeightBlend, properties);
            mossBlendDistanceProp = FindProperty(Prop._BlendDistance, properties);
            mossAngleProp = FindProperty(Prop._BlendAngle, properties);
            mossMap = FindProperty(Prop._MossMap, properties);

            enableIntersectionProp = FindProperty(Prop._EnableIntersection, properties);
            debugToggleProp = FindProperty(Prop._DebugToggle, properties, false);
            valueRemapProp = FindProperty(Prop._ValueRemap, properties);
            enableVOffsetProp = FindProperty(Prop._EnableVertexOffset, properties);
            vertexOffsetProp = FindProperty(Prop._VertexOffset, properties);
            enableShadowOffsetProp = FindProperty(Prop._EnableShadowOffset, properties);
            shadowOffsetProp = FindProperty(Prop._ShadowOffset, properties);
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material, SetMaterialKeywords);
        }

        public override void DrawSurfaceInputs(Material material) {
            base.DrawSurfaceInputs(material);

            if (enableTriplanarProp != null) {
                var enableTriplanar = DoToggleField(enableTriplanarProp, new GUIContent("Triplanar"), 0);
                if (enableTriplanar) {
                    DoVectorField(textureSizeProp, "Texture Size and Contrast");
                }
            } else {
                DoVectorField(textureSizeProp, "Texture Size and Contrast");
            }

            var enableMoss = DoToggleField(enableMossProp, new GUIContent("Moss"), 0);
            if (enableMoss) {
                _materialEditor.TexturePropertySingleLine(new GUIContent("Moss Map", "Albedo(RGB)"), mossMap);

                DoSliderField(mossScaleProp, .01f, 64);
                DoSliderField(mossSmoothnessProp, 0.01f, 2);
                EditorGUILayout.Space(4);
                DoSliderField(mossHeightBlendProp, 0, 50);
                DoSliderField(mossBlendDistanceProp, 0, 50);
                DoSliderField(mossAngleProp, 0, 180);
                EditorGUILayout.Space(4);
            }

            var intersection = DoToggleField(enableIntersectionProp, new GUIContent("Intersection"), 0);
            if (intersection) {
                DoVectorField(valueRemapProp, "Remap", 2);
                var vOffset = DoToggleField(enableVOffsetProp, new GUIContent("Vertex Offset"), 2);
                if (vOffset) {
                    DoVectorField(vertexOffsetProp, "Offset", 3);
                }
            }

            var enableShadowBias= DoToggleField(enableShadowOffsetProp, new GUIContent("ShadowOffset"), 0);
            if (enableShadowBias)
            {
                DoVectorField(shadowOffsetProp, "shadowOffset", 2);
            }


            EditorGUILayout.Space(8);
            DoToggleField(debugToggleProp, "Debug");
            EditorGUILayout.Space(8);

            DrawTileOffset(_materialEditor, _baseMapProp);
        }

        public static void SetMaterialKeywords(Material material) {
            SimpleLitShaderGUI.SetTwoLevelMaterialQuality(material);

            float needMoss = 0, needIntersection = 0;

            if (material.HasProperty(Prop._EnableIntersection)) {
                needIntersection = material.GetFloat(Prop._EnableIntersection);
                CoreUtils.SetKeyword(material, Keyword._VCOLOR, needIntersection == 1.0f);
            }

            if (material.HasProperty(Prop._EnableTriplanar)) {
                var triplanar = material.GetFloat(Prop._EnableTriplanar);
                CoreUtils.SetKeyword(material, Keyword._TRIPLANAR, triplanar == 1.0f);
            }

            if (material.HasProperty(Prop._DebugToggle)) {
                var debug = material.GetFloat(Prop._DebugToggle);
                CoreUtils.SetKeyword(material, LegacyKeyword._DEBUG, debug == 1.0f);
            }
            if (material.HasProperty(Prop._EnableShadowOffset))
            {
                var shadowOffset = material.GetFloat(Prop._EnableShadowOffset) ;
                CoreUtils.SetKeyword(material, Keyword._EnableShadowOffset, shadowOffset==1.0f);

            }
            // CoreUtils.SetKeyword(material, Keyword._NEED_POS_WS, needIntersection + needMoss > 0.0f);
        }

        public override void DrawMaterialQuality(Material mat) {
            if (!SimpleLitShaderGUI.DrawTwoLevelMaterialQuality(_materialEditor, _MaterialQualityProp)) return;
            if (EditorGUI.EndChangeCheck()) {
                foreach (var obj in _materialEditor.targets)
                    MaterialChanged((Material) obj);
            }
        }
    }
}