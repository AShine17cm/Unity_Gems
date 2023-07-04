using UnityEngine;
using UnityEditor;
using System;

public class Note : MaterialPropertyDrawer
{
    protected string _note;

    public Note()
    {
        _note = "";
    }

    public Note(string note)
    {
        _note = note;
    }

    public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor)
    {
//		Material mat = editor.target as Material;
//	
//		SerializedObject serializedObject 			= new UnityEditor.SerializedObject(mat);
//		SerializedProperty tex 	= serializedObject.FindProperty("_MainTex");
//
//		Debug.Log (tex.name);


        position.height = 32f;
        EditorGUI.HelpBox(position, _note, MessageType.Info);

        Space(5);
    }

    void Space(int size)
    {
        for (int i = 0; i < size; i++)
        {
            EditorGUILayout.Space();
        }
    }
}