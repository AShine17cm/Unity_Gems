using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace URP.Editor
{
    public  class VFXShaderGUI : VFXXShaderGUI
    {
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
          
        }

        public override void MaterialChanged(Material material)
        {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material);
          
        }

        //public override void DrawBaseMapProperties(Material material)
        //{
        //    base.DrawBaseMapProperties(material);
        //}

        public override void DrawSurfaceInputs(Material material)
        {
            base.DrawSurfaceInputs(material);
        }


    }
}
