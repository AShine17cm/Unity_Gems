using UnityEngine;
using UnityEditor;
using System.Collections;
using System;

public class ToggleLeft : MaterialPropertyDrawer
{

	protected string keyword;

	public ToggleLeft(string k)
	{
		keyword = k;
	}

	// Draw the property inside the given rect
	public override void OnGUI (Rect position, MaterialProperty prop, String label, MaterialEditor editor)
	{

		EditorGUI.showMixedValue = false;
		EditorGUI.BeginChangeCheck();
		EditorGUI.showMixedValue = prop.hasMixedValue;

		for(int i=0; i<editor.targets.Length; i++)
		{
			Material mat = editor.targets[i] as Material;

			// Setup
			bool value = mat.IsKeywordEnabled(keyword);

			// Use default labelWidth
			EditorGUIUtility.labelWidth = 0f;
			EditorGUIUtility.fieldWidth = 64f;

			position.y += 3f;
			value = EditorGUI.ToggleLeft (position, label, value, EditorStyles.boldLabel);


			if (EditorGUI.EndChangeCheck ()) 
			{
				if (value) {
					EditorGUILayout.Space ();
				}

				if (mat != null) {
					prop.floatValue = value ? 1.0f : 0.0f;
					SetKeyword (mat, keyword, value);
				}
			}
		}

	}

	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{		
		return base.GetPropertyHeight (prop, label, editor);
	}

	static void SetKeyword(Material m, string keyword, bool state)
	{
		if (state)
			m.EnableKeyword (keyword);
		else
			m.DisableKeyword (keyword);
	}
}