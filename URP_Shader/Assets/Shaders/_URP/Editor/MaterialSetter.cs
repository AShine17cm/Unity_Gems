using System.Collections;
using UnityEditor;
using UnityEngine;

namespace URP {
    public class MaterialSetter : AssetPostprocessor {
        void OnPostprocessMaterial(Material material) {
            Debug.Log($"Process {material.name}");
            material.SetOptions();
        }

        void OnPreprocessAsset() {
            // if (assetPath.Contains(".mat")) {
            //     EditorCoroutineUtility.StartCoroutine(ProcessMaterial(assetPath), this);
            // }
        }

        IEnumerator ProcessMaterial() {
            // yield return new WaitForSeconds(.1f);
            yield return null;
            var material = AssetDatabase.LoadAssetAtPath<Material>(assetPath);
            material.SetOptions();
        }
    }

    public class MaterialSaver : SaveAssetsProcessor {
        static string[] OnWillSaveAssets(string[] paths) {
            // Debug.Log("On will save assets");
            foreach (var path in paths) {
                ProcessMaterial(path);
            }

            return paths;
        }

        static void ProcessMaterial(string path) {
            if (!path.Contains(".mat")) {
                return;
            }

            // yield return new WaitForSeconds(.1f);
            var material = AssetDatabase.LoadAssetAtPath<Material>(path);
            material.SetOptions();
        }
    }

    public static class MaterialOptions {
        public static void SetOptions(this Material material) {
            if (material != null) {
                // Debug.Log($"Preprocess {material.name}");
                //material.enableInstancing = true;
                //material.DisableKeyword(Keyword._SPECULARHIGHLIGHTS_OFF);
                //material.SetFloat(Prop._SpecularHighlights, 1);

                if (material.HasProperty(Prop._ReadProps)) {
                    material.SetFloat(Prop._ReadProps, 1);
                    material.EnableKeyword(Keyword._READ_PROPS);
                }
            }
        }
    }
}