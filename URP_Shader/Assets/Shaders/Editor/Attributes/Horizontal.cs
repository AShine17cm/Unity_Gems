using UnityEditor;
using UnityEngine;

public class HorizontalStart : HeightZero
{
    protected string Label = "";

    public HorizontalStart()
    {
        Label = "";
    }

    public HorizontalStart(string label)
    {
        Label = label;
    }

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        GUILayout.BeginHorizontal();
        if (Label != "")
        {
            EditorGUILayout.LabelField(Label, EditorStyles.boldLabel);
        }
        
    }
}

public class HorizontalEnd : HeightZero
{
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        GUILayout.EndHorizontal();
    }
}