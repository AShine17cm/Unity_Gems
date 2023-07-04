#if UNITY_EDITOR

using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using URP;
using URP.Tools;

public class URPShaderBuildProcessor : IPreprocessShaders {
    // Only Release Strip

    // Dev Strip
    public static readonly List<ShaderKeyword> devStrip = new List<ShaderKeyword>() {
                                                                                        new ShaderKeyword(LegacyKeyword
                                                                                                             ._DEBUG),
                                                                                        new ShaderKeyword(LegacyKeyword
                                                                                                             .MATERIAL_QUALITY_HIGH),
                                                                                        new ShaderKeyword(LegacyKeyword
                                                                                                             .MATERIAL_QUALITY_MEDIUM),
                                                                                        new ShaderKeyword(LegacyKeyword
                                                                                                             .MATERIAL_QUALITY_LOW)
                                                                                    };


    public static readonly List<ShaderKeyword> requriedKeywords = new List<ShaderKeyword>() {
                                                                                            };


    public int callbackOrder => 0;
    public static ShaderVariantSets s_shaderVariantSets;
    public static List<string> s_UserDefinedList;
    const string INSTANCING_ON = "INSTANCING_ON";

    public void OnProcessShader(Shader shader,
                                ShaderSnippetData snippet,
                                IList<ShaderCompilerData> data) {
        if (s_shaderVariantSets == null) {
            s_shaderVariantSets =
                AssetDatabase.LoadAssetAtPath<ShaderVariantSets>("Assets/z_ArtTools/Shader Variant Sets.asset");
        }

        if (s_shaderVariantSets == null) {
            Debug.Log("Cant find Shader Variant Sets");
            return;
        } else {
            s_UserDefinedList = s_shaderVariantSets.userDefinedKeywords;
        }

        Debug.Log($"Process Shader - {shader.name}, {snippet.shaderType}-{snippet.passName}-{snippet.passType}");

        // Skip shader
        if (s_shaderVariantSets.skipShaders && !s_shaderVariantSets.ContainShader(shader)) {
            if ((!shader.name.Contains("Hidden") || shader.name.Contains("TerrainEngine")) &&
                !shader.name.Contains("Pass")) {
                Debug.Log($"Skip Shader 0: {shader.name}");
                data.Clear();
                return;
            }
        }

        // Strip
        for (int i = 0; i < data.Count; i++) {
            s_shaderVariantSets._totalDataCount++;
            var removed = false;
            var shaderKeywordSet = data[i].shaderKeywordSet;

            // test
            // if (i < 10) {
            //     var k = "";
            //     foreach (var keyword in shaderKeywordSet.GetShaderKeywords()) {
            //         k += keyword.GetKeywordName() + " ";
            //     }
            //
            //     Debug.Log($"[{i}] {k}");
            // }

            // dev
            foreach (var keyword in devStrip) {
                if (shaderKeywordSet.IsEnabled(keyword)) {
                    data.RemoveAt(i);
                    --i;
                    removed = true;
                    s_shaderVariantSets._removeCount++;
                    break;
                }
            }

            if (removed)
                continue;

            // required
            foreach (var keyword in requriedKeywords) {
                if (!shaderKeywordSet.IsEnabled(keyword)) {
                    data.RemoveAt(i);
                    --i;
                    removed = true;
                    s_shaderVariantSets._removeCount++;
                    break;
                }
            }

            if (removed) {
                continue;
            }

            // Get Keyword set
            var set = shaderKeywordSet.GetShaderKeywords();
            var customizedSet = "";
            var originSet = "";
            for (int j = 0; j < set.Length; j++) {
                var s = set[j].GetName();
                originSet += s;
                originSet += ' ';
                if (s_UserDefinedList.Contains(s)) {
                    customizedSet += s;
                    customizedSet += ' ';
                }
            }

            customizedSet = customizedSet.Trim();
            Debug.Log($"{shader.name}{i}{snippet.passName}{data[i].shaderCompilerPlatform} : {originSet}\n-{customizedSet}");

            if (s_shaderVariantSets.skipIfNoInstancing) {
                if (!originSet.Contains(INSTANCING_ON)) {
                    data.RemoveAt(i);
                    --i;
                    removed = true;
                    s_shaderVariantSets._removeCount++;
                }
            }

            if (removed) {
                Debug.Log($"Remove 0: {shader.name} - {originSet}");
                continue;
            }

            if (string.IsNullOrEmpty(customizedSet)) {
                continue;
            }

            // Match Keyword set
            if (!s_shaderVariantSets.ContainKeyset(customizedSet)) {
                data.RemoveAt(i);
                --i;
                removed = true;
                s_shaderVariantSets._removeCount++;
            }

            if (removed) {
                Debug.Log($"Remove 1: {shader.name} - {customizedSet}");
                continue;
            }

            // Match keyword set 2
            if (!s_shaderVariantSets.MatchShaderKeyset(shader, customizedSet)) {
                data.RemoveAt(i);
                --i;
                removed = true;
                s_shaderVariantSets._removeCount++;
            }

            if (removed) {
                Debug.Log($"Remove 2: {shader.name} - {customizedSet}");
                continue;
            }
        }

        // Only Release Strip
        if (EditorUserBuildSettings.development) {
            return;
        }
    }
}
#endif