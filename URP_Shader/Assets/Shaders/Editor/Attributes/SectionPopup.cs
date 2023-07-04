using UnityEngine;
using UnityEditor;
using System;

public class SectionPopup : MaterialPropertyDrawer
{
    protected string[] _keywords;
    protected string _keywordName;

    public SectionPopup(string keywordBase, params string[] names)
    {
        ValidateKeyword(keywordBase);
        _keywords = names;
    }

    public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor)
    {
        // Setup
        int value = (int) prop.floatValue;

        EditorGUI.BeginChangeCheck();
        EditorGUI.showMixedValue = prop.hasMixedValue;
        // Use default labelWidth
        EditorGUIUtility.labelWidth = 0f;
        EditorGUIUtility.fieldWidth = 64f;

        value = EditorGUILayout.Popup(label, value, _keywords);

        EditorGUI.showMixedValue = false;

        if (EditorGUI.EndChangeCheck())
        {
            for (int i = 0; i < editor.targets.Length; i++)
            {
                Material mat = editor.targets[i] as Material;
                if (mat != null)
                {
                    // Enable selected option
                    string toEnable = (_keywordName + _keywords[value].ToUpper()) as string;

                    // Disable all keywords
                    for (int y = 0; y < _keywords.Length; y++)
                    {
                        if (_keywords[y].ToUpper() == "NONE")
                        {
                            continue;
                        }

                        // Disable all other options
                        string toDisable = (_keywordName + _keywords[y].ToUpper()) as string;
                        if (toDisable != toEnable)
                        {
                            SetKeyword(mat, toDisable, false);
                        }
                    }

                    prop.floatValue = value;

                    if (_keywords[value].ToLower() != "none")
                    {
                        SetKeyword(mat, toEnable, true);
                    }
                }
            }
        }
    }

    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }

    static void SetKeyword(Material m, string keyword, bool state)
    {
        if (state)
            m.EnableKeyword(keyword);
        else
            m.DisableKeyword(keyword);
    }

    void ValidateKeyword(string keywordBase)
    {
        _keywordName = keywordBase.ToUpper();
        _keywordName += "_";
    }
}