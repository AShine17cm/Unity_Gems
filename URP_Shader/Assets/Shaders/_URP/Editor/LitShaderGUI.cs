using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class LitShaderGUI : BaseShaderGUI {
     

        public override void FindProperties(MaterialProperty[] properties) {
            base.FindProperties(properties);
      
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

            if (GetQuality == 1) {
                DrawSpecColor(material);
            }
        }
    }
}