#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;

public class BoxStart : HeightZero
{
    protected Color Col = Color.white;
    protected string Label = "";

    #region

    public BoxStart()
    {
        Col = Color.white;
    }

    public BoxStart(string label)
    {
        Col = Color.white;
        Label = label;
    }

    public BoxStart(string label, float r, float g, float b)
    {
        Label = label;
        Col = new Color(r, g, b, 1f);
    }

    public BoxStart(float r, float g, float b)
    {
        Col = new Color(r, g, b, 1f);
    }

    #endregion

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        GUI.backgroundColor = Col;
        GUILayout.BeginVertical("", GUI.skin.box);
        GUI.backgroundColor = Color.white;

        if (Label != "")
        {
            EditorGUILayout.LabelField(Label, EditorStyles.boldLabel);
        }
    }
}

public class BoxEnd : HeightZero
{
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        GUILayout.EndVertical();
        GUI.backgroundColor = Color.white;
    }
}

#endif