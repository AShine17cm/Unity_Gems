using System;
using UnityEditor;
using UnityEngine;

namespace URP.Editor {
    public class UnlitShaderGUI : BaseShaderGUI {
        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");

            SetMaterialKeywords(material);
        }
    }
}