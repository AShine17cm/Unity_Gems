using UnityEditor;
using UnityEngine;

public class Indent : MaterialPropertyDrawer
{
    protected int IndentLevel = 1;

    public Indent(int indentLevel)
    {
        IndentLevel = indentLevel;
    }


    public Indent()
    {
    }


    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        for (int i = 0; i < IndentLevel; i++)
        {
            ++EditorGUI.indentLevel;
        }

        base.OnGUI(position, prop, label, editor);

        for (int i = 0; i < IndentLevel; i++)
            --EditorGUI.indentLevel;
    }
}