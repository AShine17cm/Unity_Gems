using System;
using UnityEngine;

namespace URP.Editor {
    public class PBRDebugGUI : BaseShaderGUI {
        protected override string[] GetDebugMode => new[] {
                                                             "NONE", //0
                                                             "Albedo", //1
                                                             "Metallic", //2
                                                             "Smoothness", //3
                                                             "NormalTS", //4
                                                             "Occlusion", //5
                                                             "Specular", //6
                                                             "Emission", //7
                                                             "Alpha", //8
                                                             "VertexLighting", //9
                                                             "BakedGI", //10

                                                             "BRDF_Diffuse", //11
                                                             "BRDF_Specular", //12
                                                             "BRDF_PerceptualRoughness", //13
                                                             "BRDF_Rougness", //14
                                                             "BRDF_Rougness2", //15
                                                             "BRDF_GrazingTerm", //16
                                                             "BRDF_NormalizationTerm", //17
                                                             "BRDF_Roughness2MinusOne", //18
                                                             
                                                             "BRDF_BakedGI", //16
                                                             "BRDF_DirectPBR", //14
                                                             "BRDF_GI", //15
                                                             "BRDF_IndirectDiffuse", //16
                                                             "BRDF_IndirectSpecular", //17


                                                             "BRDF_AdditionalLight", //18
                                                         };
        public override void MaterialChanged(Material material) {
            if (material == null)
                throw new ArgumentNullException("material");
            SetMaterialKeywords(material);
        }
    }
}