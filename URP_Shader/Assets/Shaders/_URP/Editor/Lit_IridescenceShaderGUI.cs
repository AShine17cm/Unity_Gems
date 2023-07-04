using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace URP.Editor {
    public class Lit_IridescenceShaderGUI : BaseShaderGUI {

        public static class Styles
        {
            public static GUIContent maskText = new GUIContent("MaskMap",
                "Separate lit and Iridescence,Mask > 0 is Iridescence,else is lit");

            public static GUIContent iridescenceThicknessText = new GUIContent("Thickness",
                "Thickness of the thin-film. Unit is micrometer, means 0.5 is 500nm.");

            public static GUIContent iridescenceThicknessMapText = new GUIContent("Thickness Map",
                "Specifies the Iridescence Thickness map (R) for this Material.");

            public static GUIContent iridescenceThicknessRemapText = new GUIContent("Remap",
                "Iridescence Thickness remap");

            public static GUIContent iridescenceEta2Text = new GUIContent("Thin-film IOR (η₂)",
                "Index of refraction of the thin-film.");

            public static GUIContent iridescenceEta3Text = new GUIContent("Base IOR (η₃)",
                "The real part of the index of refraction of the base layer. Refer to https://refractiveindex.info/ for more information.");

            public static GUIContent iridescenceKappa3Text = new GUIContent("Base IOR (κ₃)",
                "The imaginary part of the index of refraction of the base layer. Refer to https://refractiveindex.info/ for more information.");

        }

        public struct Lit_IridescenceProperties
        {
        
            public MaterialProperty MaskMapProp;
            public MaterialProperty IridescenceThicknessProp;
            public MaterialProperty IridescenceThicknessMapProp;
            public MaterialProperty IridescenceThicknessRemapProp;
            public MaterialProperty IridescenceEta2Prop;
            public MaterialProperty IridescenceEta3Prop;
            public MaterialProperty IridescenceKappa3Prop;

            public Lit_IridescenceProperties(MaterialProperty[] properties)
            {
            MaskMapProp=FindProperty(Prop._MaskMap, properties, false);
            IridescenceThicknessProp = FindProperty(Prop._IridescenceThickness, properties, false);
            IridescenceThicknessMapProp = FindProperty(Prop._IridescenceThicknessMap, properties, false);
            IridescenceThicknessRemapProp = FindProperty(Prop._IridescenceThicknessRemap, properties, false);
            IridescenceEta2Prop = FindProperty(Prop._IridescneceEta2, properties, false);
            IridescenceEta3Prop = FindProperty(Prop._IridescneceEta3, properties, false);
            IridescenceKappa3Prop = FindProperty(Prop._IridescneceKappa3, properties, false);

            }
        }
        Lit_IridescenceProperties _lit_IridescenceProperties;
        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            _lit_IridescenceProperties = new Lit_IridescenceProperties(properties);
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
            if (material.shader.maximumLOD == HIGH_QUALITY)
            {
            DoIridescenceArea(_lit_IridescenceProperties, _materialEditor);
            }
            if (GetQuality == 1) {
                DrawSpecColor(material);
            }
          
        }

        public void DoIridescenceArea(Lit_IridescenceProperties properties, MaterialEditor materialEditor)
        {
            DoHeader("ThinFilm");
            materialEditor.TexturePropertySingleLine(Styles.maskText, properties.MaskMapProp);
            bool hasThicknessMap = properties.IridescenceThicknessMapProp.textureValue != null;
            materialEditor.TexturePropertySingleLine(hasThicknessMap ?
            Styles.iridescenceThicknessMapText : Styles.iridescenceThicknessText, properties.IridescenceThicknessMapProp,
            hasThicknessMap ? properties.IridescenceThicknessRemapProp : properties.IridescenceThicknessProp);
            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(properties.IridescenceEta2Prop, Styles.iridescenceEta2Text);
            materialEditor.ShaderProperty(properties.IridescenceEta3Prop, Styles.iridescenceEta3Text);
            materialEditor.ShaderProperty(properties.IridescenceKappa3Prop, Styles.iridescenceKappa3Text);

            EditorGUI.indentLevel--;

        }
    }
}