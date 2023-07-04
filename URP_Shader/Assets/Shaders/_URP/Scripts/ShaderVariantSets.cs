#if UNITY_EDITOR

using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
// #if ODIN_INSPECTOR
// using Sirenix.OdinInspector;
// #endif
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using Debug = UnityEngine.Debug;

namespace URP.Tools {
    [CreateAssetMenu(menuName = "URP/ShaderVariantSets")]
    public class ShaderVariantSets : ScriptableObject {


        [System.Serializable]
        public class ShaderVariants {
            public Shader shader;
            public List<VariantSet> variantSets;

            public ShaderVariants(Shader shader) {
                this.shader = shader;
                variantSets = new List<VariantSet>();
            }

            public void AddVariantSet(string keyset, Material material) {
                var set = variantSets.Find(k => k.keyset == keyset);
                if (set == null) {
                    set = new VariantSet(keyset, material);
                    variantSets.Add(set);
                } else {
                    if (!set.mats.Contains(material)) {
                        set.mats.Add(material);
                    }
                }
            }

            public bool ContainsKeyset(string keyset) {
                var variantSet = variantSets.Find(vs => vs.keyset == keyset);
                return variantSet != null;
            }
        }

        [System.Serializable]
        public class VariantSet {
            // #if ODIN_INSPECTOR
            // [HorizontalGroup(), HideLabel, DisplayAsString]
            // #endif
            public string keyset;

            // #if ODIN_INSPECTOR
            // [HorizontalGroup(16), HideLabel, DisplayAsString]
            // #endif
            public int count;
            public List<Material> mats;

            public VariantSet(string keyset, Material material) {
                this.keyset = keyset;
                count = 1;
                mats = new List<Material>() {material};
            }
        }

        [Header("Config")]
        // #if ODIN_INSPECTOR
        // [InfoBox("Add All the folder contains materials")]
        // [ListDrawerSettings(Expanded = true), FolderPath(RequireExistingPath = true)]
        // #endif
        public string[] materialFolders;

        public bool skipShaders = true;
        public bool skipIfNoInstancing = false;

        [Header("Used By Materials")]
        [SerializeField] List<ShaderVariants> _shaderVariantsList;

        // [DisplayAsString]
        [SerializeField] List<VariantSet> _variantSets;

        [SerializeField] List<Shader> _shaderList;

        [Space]
        // [DisplayAsString]
        public List<string> keywordsList;

        public List<Material> mats;

        public string keywordName = "_MAIN_LIGHT_SHADOWS";

        [Header("Customized Keywords Consts")]
        [Space]
        // [DisplayAsString]
        public List<string> customizedKeywords = Keyword.CustomizedUserDefined;

        public List<string> legacyKeywords;
        public List<string> urpDefinedKeywords;
        public List<string> userDefinedKeywords;

        // #if ODIN_INSPECTOR
        // [DisplayAsString]
        // #endif
        public int _totalDataCount;

        // #if ODIN_INSPECTOR
        // [DisplayAsString]
        // #endif
        public int _removeCount;

        // #if ODIN_INSPECTOR
        // [Button]
        // #endif
        [ContextMenu("Test")]
        void Test() {
            var key = new ShaderKeyword(keywordName);
            Debug.Log($"key: {key.GetName()} {key.GetKeywordType()}");
            urpDefinedKeywords = Keyword.UserDefinedKeywordList();
            var s_shaderVariantSets =
                AssetDatabase.LoadAssetAtPath<ShaderVariantSets>("Assets/z_ArtTools/Shader Variant Sets.asset");
            Debug.Log(s_shaderVariantSets.name);
        }

        [ContextMenu("Generate")]
        // #if ODIN_INSPECTOR
        // [Button]
        // #endif
        public void GetShaderVariantSets() {
            GetMaterials();
            _removeCount = _totalDataCount = 0;
            legacyKeywords = Keyword.LegacyKeywordList;
            customizedKeywords = Keyword.CustomizedUserDefined;
            urpDefinedKeywords = Keyword.UserDefinedKeywordList();

            var changeKeywordMatCount = 0;
            _variantSets = new List<VariantSet>();
            _shaderList = new List<Shader>();
            _shaderVariantsList = new List<ShaderVariants>();
            keywordsList = new List<string>();

            foreach (var mat in mats) {
                if (!_shaderList.Contains(mat.shader)) {
                    _shaderList.Add(mat.shader);
                }

                var keywords = mat.shaderKeywords;
                var keys = "";
                var changedKeyword = false;
                foreach (var keyword in keywords) {
                    if (legacyKeywords.Contains(keyword)) {
                        mat.DisableKeyword(keyword);
                        changedKeyword = true;
                        continue;
                    }

                    if (!customizedKeywords.Contains(keyword)) {
                        continue;
                    }

                    if (!keywordsList.Contains(keyword)) {
                        keywordsList.Add(keyword);
                    }

                    keys += keyword;
                    keys += ' ';
                }

                if (changedKeyword) {
                    changeKeywordMatCount++;
                }

                keys = keys.Trim();

                if (string.IsNullOrEmpty(keys)) {
                    continue;
                }

                var sv = _shaderVariantsList.Find(s => s.shader == mat.shader);
                if (sv == null) {
                    sv = new ShaderVariants(mat.shader);
                    _shaderVariantsList.Add(sv);
                }

                sv.AddVariantSet(keys, mat);

                var keyset = _variantSets.Find(v => v.keyset == keys);

                if (keyset != null) {
                    keyset.count++;
                    keyset.mats.Add(mat);
                } else {
                    _variantSets.Add(new VariantSet(keys, mat));
                }
            }

            Debug.Log($"Total Changed Keyword Material Count: {changeKeywordMatCount}");
            _variantSets.Sort((x, y) => x.keyset.CompareTo(y.keyset));
            URPShaderBuildProcessor.s_shaderVariantSets = null;
            AssetDatabase.SaveAssets();
        }




        public bool ContainKeyset(string keyset) {
            return _variantSets.Find(v => v.keyset == keyset) != null;
        }

        public bool MatchShaderKeyset(Shader shader, string keyset) {
            var shaderVars = _shaderVariantsList.Find(sv => sv.shader == shader);
            if (shaderVars != null) {
                return shaderVars.ContainsKeyset(keyset);
            }

            return false;
        }

        public bool ContainShader(Shader shader) {
            return _shaderList.Contains(shader);
        }

        void GetMaterials() {
            mats = new List<Material>();

            var guids = AssetDatabase.FindAssets("t:Material", materialFolders);
            foreach (var guid in guids) {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (string.IsNullOrEmpty(path)) {
                    continue;
                }

                var mat = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (mat != null) {
                    mats.Add(mat);
                }
            }
        }


    }
}
#endif