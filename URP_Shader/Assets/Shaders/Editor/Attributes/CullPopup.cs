/*
 * --------------------------------
 * Properties:
 * --------------------------------
 * 	[CullPopup]
	_Cull("Culling Mode",float) = 0
 * --------------------------------
  Subshader:
 * --------------------------------
	Cull [_Cull]
 */

using UnityEngine;
using UnityEditor;
using System.Collections;
using System;

public class CullPopup : MaterialPropertyDrawer {

	protected enum CullModes{
		Off,
		Front,
		Back
	}
		
	protected string _cullMode;

	protected CullModes CullMode;

	public CullPopup (){
		_cullMode = "_Cull";
	}

	public CullPopup (string str){
		_cullMode = str;
	}

	// Draw the property inside the given rect
	public override void OnGUI (Rect position, MaterialProperty prop, String label, MaterialEditor editor)
	{

		// Setup
		CullModes selected = (CullModes)prop.floatValue;  

		EditorGUI.BeginChangeCheck();
		EditorGUI.showMixedValue = prop.hasMixedValue;
		// Use default labelWidth
		EditorGUIUtility.labelWidth = 0f;
		EditorGUIUtility.fieldWidth = 64f;

		selected = (CullModes)EditorGUILayout.EnumPopup("Cull Mode",selected);
		//BlendMode = (BlendModes)EditorGUILayout.EnumPopup("Blend Mode", BlendMode);
		EditorGUI.showMixedValue = false;

		// If Changed or first time setup
		if (EditorGUI.EndChangeCheck() || prop.floatValue == 0)
		{
			for(int i=0; i<editor.targets.Length; i++)
			{
				Material mat = editor.targets[i] as Material;
				if(mat != null)
				{
					mat.SetFloat (_cullMode, (float)selected);
					//SetupMaterialWithBlendMode (mat, selected);
					prop.floatValue = (float)selected;
				}
			}
		}
	}
}
