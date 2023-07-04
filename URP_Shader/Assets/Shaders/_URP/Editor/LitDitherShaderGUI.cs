using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class LitDitherShaderGUI : BaseShaderGUI {

        protected MaterialProperty _RimColor;
        protected MaterialProperty _RimWidth;
        protected MaterialProperty _RimIntensity;
        protected MaterialProperty _RimSmoothness;
        protected MaterialProperty _TranprantAlpha;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
        
            _RimColor = FindProperty(Prop._RimColor, properties, false);
            _RimWidth = FindProperty(Prop._RimWidth, properties, false);
            _RimIntensity = FindProperty(Prop._RimIntensity, properties, false);
            _RimSmoothness = FindProperty(Prop._RimSmoothness, properties, false);
            _TranprantAlpha = FindProperty(Prop._TranprantAlpha, properties, false);

        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, null);
        }

        public override void DrawBaseProperties(Material material) {
            DrawNSArea(material);
            DrawEmissionArea();
            EditorGUILayout.Space(8);
        
            DrawPatternProp();
            EditorGUILayout.Space(8);

            DoColorField(_RimColor, 0, true, false, true);
            DoSliderField(_RimWidth, 0.01f, 10, 0);
            DoSliderField(_RimIntensity, 0.01f, 10, 0);
            DoSliderField(_RimSmoothness, 0.01f, 10, 0);
            DoSliderField(_TranprantAlpha, 0.01f, 1, 0);

            if (GetQuality == 1) {
                DrawSpecColor(material);
            }
        }
    }
}