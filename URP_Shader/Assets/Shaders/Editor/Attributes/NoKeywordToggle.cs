using UnityEditor;
using UnityEngine;

public class NoKeywordToggle : MaterialPropertyDrawer
{
    override public void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        bool state = EditorGUI.Toggle(position, label, (prop.floatValue == 1));
        if (state != (prop.floatValue == 1))
        {
            prop.floatValue = state ? 1 : 0;
        }
    }
}