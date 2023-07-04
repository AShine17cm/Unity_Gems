using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class LitTranslucencyShaderGUI : BaseShaderGUI {
        MaterialProperty _RimColor;
        MaterialProperty _RimPower;
        MaterialProperty _RimIntensity;

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
            _RimColor = FindProperty(Prop._RimColor, properties, false);
            _RimPower = FindProperty(Prop._RimPower, properties, false);
            _RimIntensity = FindProperty(Prop._RimIntensity, properties, false);
           
        }

        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material, null);
            if ((SurfaceType)material.GetFloat(Prop._Surface) == SurfaceType.Opaque)
            {
                
                SurfaceType surfaceType = SurfaceType.Transparent;
                material.SetFloat(Prop._Surface, (float)SurfaceType.Transparent);
                DoPopup(Styles.blendingMode, _blendModeProp, Enum.GetNames(typeof(BlendMode))); 
            }

        }
       

        public override void DrawBaseProperties(Material material) {
            DrawNSArea(material);
            DrawEmissionArea();
            EditorGUILayout.Space(8);
            DoColorField(_RimColor, 0, true, false, true);
            DoSliderField(_RimPower, 0.01f, 10, 0);
            DoSliderField(_RimIntensity, 0.01f, 10, 0);
            DrawPatternProp();
            DrawEnvironmentMap();
            EditorGUILayout.Space(8);

            if (GetQuality == 1) {
                DrawSpecColor(material);
            }
        }
    }
}