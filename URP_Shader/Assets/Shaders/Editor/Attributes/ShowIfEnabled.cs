/*
To use it, you simply call it like any other attribute style on the shader property. Eg for that mask value example:
[ShowIfEnabled(_MATERIAL_MASKED)] _maskThreshold ("Mask threshold", Float) = 0.333

NOTE: this is dependent on enable/disable of keywords, so the above would show the mask value when this is set to enabled:
#pragma shader_feature _MATERIAL_MASKED
In my setup, this is done in my common shaderGUI editor with Material.EnableKeyword() and Material.DisableKeyword()
*/

#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class ShowIfEnabled : MaterialPropertyDrawer
{
    protected string[] argValue;
    protected int IndentLevel = 1;
    bool bElementShow;

    //constructor permutations -- params doesn't seem to work for property drawer inputs :( -----------
    public ShowIfEnabled(string name1)
    {
        argValue = new[] {name1};
    }

    public ShowIfEnabled(string name1, string name2)
    {
        argValue = new[] {name1, name2};
    }

    public ShowIfEnabled(string name1, string name2, string name3)
    {
        argValue = new[] {name1, name2, name3};
    }

    public ShowIfEnabled(string name1, string name2, string name3, string name4)
    {
        argValue = new[] {name1, name2, name3, name4};
    }

    //-------------------------------------------------------------------------------------------------

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        bElementShow = false;

        for (int i = 0; i < editor.targets.Length; i++)
        {
            //material object that we're targetting...
            Material mat = editor.targets[i] as Material;
            if (mat != null)
            {
                //check for the dependencies:
                for (int j = 0; j < argValue.Length; j++)
                    bElementShow |= mat.IsKeywordEnabled(argValue[j]);
            }
        }

        if (bElementShow)
        {
            ++EditorGUI.indentLevel;
            editor.DefaultShaderProperty(prop, label);
            --EditorGUI.indentLevel;
        }
    }

//	//We need to override the height so it's not adding any extra (unfortunately texture drawers will still add an extra bit of padding regardless):
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}
#endif