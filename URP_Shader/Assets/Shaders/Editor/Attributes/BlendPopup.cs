/*
=========================================
Ex of use:
[BlendPopup]
_BlendMode ("BlendMode",float) = 0
-----------------------------------------
Important, the default value of this property has to be 0. 
This script will do the fisrt time setup on the material and then set it to 1. You won't see the value in the editor.
-----------------------------------------
This popup sets the blending mode on the material. So you can have Additive or Blend with the same shader.
By default it will edit properties _SrcBlend and _DstBlend that you can use as this in your shader:
Blend [_SrcBlend][_DstBlend]
=========================================
*/

using UnityEngine;
using UnityEditor;
using System.Collections;
using System;

public class BlendPopup : MaterialPropertyDrawer
{
	protected enum BlendModes{
		Additive,
		Blend,
		Opaque,
		Premultiply
	}

	protected enum BlendModesOpaque{
		Opaque,
		Cutout
	}

	protected string _src;
	protected string _dst;
	protected string _ZWrite;
	protected BlendModes BlendMode;
	protected BlendModesOpaque BlendModeopaque;
	protected bool _opaque = false;

	public BlendPopup()
	{
		_src 			= "_SrcBlend";
		_dst 			= "_DstBlend";
		_ZWrite 	= "_ZWrite";
		_opaque 	= false;
	}

	public BlendPopup(float opaque)
	{
		_opaque 	= opaque != 0 ? true : false;
		_src 			= "_SrcBlend";
		_dst 			= "_DstBlend";
		_ZWrite 	= "_ZWrite";
	}

	public BlendPopup(string src,string dst,string zwrite)
	{
		_src 			= src;
		_dst 			= dst;
		_ZWrite 	= zwrite;
	}

	// Draw the property inside the given rect
	public override void OnGUI (Rect position, MaterialProperty prop, String label, MaterialEditor editor)
	{
		EditorGUI.BeginChangeCheck();
		EditorGUI.showMixedValue = prop.hasMixedValue;
		// Use default labelWidth
		EditorGUIUtility.labelWidth = 0f;
		EditorGUIUtility.fieldWidth = 64f;

		EditorGUI.showMixedValue = false;

		if (_opaque) {
			BlendModesOpaque selected 	= (BlendModesOpaque)prop.floatValue;
			selected 								= (BlendModesOpaque)EditorGUILayout.EnumPopup ("Blend Mode", selected);
			prop.floatValue 						= (float)selected;

			// If Changed or first time setup
			if (EditorGUI.EndChangeCheck() || prop.floatValue == 0)
			{
				for(int i=0; i<editor.targets.Length; i++)
				{
					Material mat = editor.targets[i] as Material;
					if(mat != null)
					{
						SetupMaterialWithBlendModeOpaque (mat, selected);
						prop.floatValue = (float)selected;
					}
				}
			}
		} else {
			BlendModes selected 	= (BlendModes)prop.floatValue;
			selected 					= (BlendModes)EditorGUILayout.EnumPopup ("Blend Mode", selected);
			prop.floatValue 			= (float)selected;

			// If Changed or first time setup
			if (EditorGUI.EndChangeCheck() || prop.floatValue == 0)
			{
				for(int i=0; i<editor.targets.Length; i++)
				{
					Material mat = editor.targets[i] as Material;
					if(mat != null)
					{
						SetupMaterialWithBlendMode (mat, selected);
						prop.floatValue = (float)selected;
					}
				}
			}
		}

		//selected = EditorGUILayout.EnumPopup ("Blend Mode", selected);
		//BlendMode = (BlendModes)EditorGUILayout.EnumPopup("Blend Mode", BlendMode);
	}

	/// <summary>
	/// Setups the material with correct parameters for each blend mode
	/// </summary>
	/// <param name="material">Material.</param>
	/// <param name="blendMode">Blend mode.</param>
	protected void SetupMaterialWithBlendMode(Material material, BlendModes blendMode)
	{
		switch (blendMode)
		{
			case BlendModes.Additive:
				SetAdditiveMode (material);
				break;
			case BlendModes.Blend:
				SetBlendMode (material);
				break;
			case BlendModes.Opaque:
				SetOpaqueMode (material);
				break;
			case BlendModes.Premultiply:
				SetPremulMode (material);
				break;
		}
	}

	protected void SetupMaterialWithBlendModeOpaque(Material material, BlendModesOpaque blendMode)
	{
		switch (blendMode)
		{
			case BlendModesOpaque.Opaque:
				SetOpaqueMode (material);
				break;
			case BlendModesOpaque.Cutout:
				SetCutoutMode (material);
				break;
		}
	}

	private bool CustomQueue(Material material)
	{
		if (material.renderQueue != (int)UnityEngine.Rendering.RenderQueue.Transparent &&
			material.renderQueue != (int)UnityEngine.Rendering.RenderQueue.Geometry &&
			material.renderQueue != (int)UnityEngine.Rendering.RenderQueue.AlphaTest) {
			return true;			
		} else {
			return false;
		}
	}

	private void SetAdditiveMode(Material material)
	{
		material.SetOverrideTag ("RenderType", "Transparent");
		material.SetInt(_src, (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
		material.SetInt(_dst, (int)UnityEngine.Rendering.BlendMode.One);
		material.SetInt (_ZWrite, 0);
		material.DisableKeyword ("_PREMUL_ON");
		material.DisableKeyword ("_ALPHATEST_ON");
		material.renderQueue = CustomQueue(material) ? material.renderQueue : (int)UnityEngine.Rendering.RenderQueue.Transparent;
	}

	private void SetBlendMode(Material material)
	{
		material.SetOverrideTag ("RenderType", "Transparent");
		material.SetInt(_src, (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
		material.SetInt(_dst, (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
		material.SetInt (_ZWrite, 0);
		material.DisableKeyword ("_PREMUL_ON");
		material.DisableKeyword ("_ALPHATEST_ON");
		material.renderQueue = CustomQueue(material) ? material.renderQueue : (int)UnityEngine.Rendering.RenderQueue.Transparent;
	}

	private void SetPremulMode(Material material)
	{
		material.SetOverrideTag ("RenderType", "Transparent");
		material.SetInt (_src, (int)UnityEngine.Rendering.BlendMode.One);
		material.SetInt (_dst, (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
		material.SetInt (_ZWrite, 0);
		material.EnableKeyword ("_PREMUL_ON");
		material.DisableKeyword ("_ALPHATEST_ON");
		material.renderQueue =  CustomQueue(material)  ? material.renderQueue : (int)UnityEngine.Rendering.RenderQueue.Transparent;
	}

	private void SetOpaqueMode(Material material)
	{
		material.SetOverrideTag ("RenderType", "Opaque");
		material.SetInt (_src, (int)UnityEngine.Rendering.BlendMode.One);
		material.SetInt (_dst, (int)UnityEngine.Rendering.BlendMode.Zero);
		material.SetInt (_ZWrite, 1);
		material.DisableKeyword ("_PREMUL_ON");
		material.DisableKeyword ("_ALPHATEST_ON");
		material.renderQueue = CustomQueue(material) ? material.renderQueue : (int)UnityEngine.Rendering.RenderQueue.Geometry;
	}

	private void SetCutoutMode(Material material)
	{
		material.SetOverrideTag ("RenderType", "TransparentCutout");
		material.SetInt (_src, (int)UnityEngine.Rendering.BlendMode.One);
		material.SetInt (_dst, (int)UnityEngine.Rendering.BlendMode.Zero);
		material.SetInt (_ZWrite, 1);
		material.DisableKeyword ("_PREMUL_ON");
		material.EnableKeyword ("_ALPHATEST_ON");
		material.renderQueue = CustomQueue(material) ? material.renderQueue : (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
	}
		
	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{		
		return 0;
	}

	static void SetKeyword(Material m, string keyword, bool state)
	{
		if (state)
			m.EnableKeyword (keyword);
		else
			m.DisableKeyword (keyword);
	}
}
