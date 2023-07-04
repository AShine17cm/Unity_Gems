using System;
using UnityEditor;
using UnityEngine;

namespace URP.Editor {
    public class ScopeShaderGUI : BaseShaderGUI {
        MaterialProperty _ScaleProp;

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            _ScaleProp = FindProperty(Prop._ScaleProp, properties, false);
        }
        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material);
        }
        public override void DrawBaseProperties(Material material)
        {
            DoSliderField(_ScaleProp, 1, 10);
        }

    }
}