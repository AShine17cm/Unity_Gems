using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class CustomShaderGUI : ShaderGUI
{
	MaterialEditor editor;
	Object[] materials;				//一次编辑多个材质
	MaterialProperty[] properties;
	bool showPresets;
	bool Clipping
	{
		set => SetProperty("_Clipping", "_CLIPPING", value);
	}

	bool PremultiplyAlpha
	{
		set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
	}

	BlendMode SrcBlend
	{
		set => SetProperty("_SrcBlend", (float)value);
	}

	BlendMode DstBlend
	{
		set => SetProperty("_DstBlend", (float)value);
	}

	bool ZWrite
	{
		set => SetProperty("_ZWrite", value ? 1f : 0f);
	}
	RenderQueue RenderQueue
	{
		set
		{
			foreach (Material m in materials)
			{
				m.renderQueue = (int)value;
			}
		}
	}
	public override void OnGUI(
		MaterialEditor materialEditor, MaterialProperty[] properties
	)
	{
		base.OnGUI(materialEditor, properties);

		editor = materialEditor;
		materials = materialEditor.targets;
		this.properties = properties;

		EditorGUILayout.Space();
		showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
		if(showPresets)
        {
			OpaquePreset();
			ClipPreset();
			FadePreset();
			TransparentPreset();
        }
	}
	void SetProperty(string name, float value)
	{
		FindProperty(name, properties).floatValue = value;
	}
	void SetKeyword(string keyword, bool enabled)
	{
		if (enabled)
		{
			foreach (Material m in materials)
			{
				m.EnableKeyword(keyword);
			}
		}
		else
		{
			foreach (Material m in materials)
			{
				m.DisableKeyword(keyword);
			}
		}
	}
	void SetProperty(string name, string keyword, bool value)
	{
		SetProperty(name, value ? 1f : 0f);
		SetKeyword(keyword, value);
	}

	bool PresetButton(string name)
	{
		if (GUILayout.Button(name))
		{
			editor.RegisterPropertyChangeUndo(name);
			return true;
		}
		return false;
	}

	void OpaquePreset()
	{
		if (PresetButton("Opaque"))
		{
			Clipping = false;
			PremultiplyAlpha = false;
			SrcBlend = BlendMode.One;
			DstBlend = BlendMode.Zero;
			ZWrite = true;
			RenderQueue = RenderQueue.Geometry;
		}
	}

	void ClipPreset()
	{
		if (PresetButton("Clip"))
		{
			Clipping = true;
			PremultiplyAlpha = false;
			SrcBlend = BlendMode.One;
			DstBlend = BlendMode.Zero;
			ZWrite = true;
			RenderQueue = RenderQueue.AlphaTest;
		}
	}

	void FadePreset()//这个没做
	{
		if (PresetButton("Fade"))
		{
			Clipping = false;
			PremultiplyAlpha = false;
			SrcBlend = BlendMode.SrcAlpha;
			DstBlend = BlendMode.OneMinusSrcAlpha;
			ZWrite = false;
			RenderQueue = RenderQueue.Transparent;
		}
	}
	void TransparentPreset()
	{
		if (PresetButton("Transparent"))
		{
			Clipping = false;
			PremultiplyAlpha = true;
			SrcBlend = BlendMode.One;
			DstBlend = BlendMode.OneMinusSrcAlpha;
			ZWrite = false;
			RenderQueue = RenderQueue.Transparent;
		}
	}
}
