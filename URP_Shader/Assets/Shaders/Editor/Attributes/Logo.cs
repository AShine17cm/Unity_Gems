using UnityEngine;
using UnityEditor;

using System;

public class Logo : MaterialPropertyDrawer {
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
        var tex = Resources.Load("logo") as Texture2D;
        GUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        GUILayout.Label(tex);
        GUILayout.FlexibleSpace();
        GUILayout.EndHorizontal();
    }
}
