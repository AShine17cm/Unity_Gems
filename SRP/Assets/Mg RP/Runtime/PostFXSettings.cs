using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName = "Rendering/Mg Post FX Settings")]
public class PostFXSettings : ScriptableObject
{
    [SerializeField]
    Shader shader = default;

	[System.NonSerialized]
	Material material;

	public Material Material
	{
		get
		{
			if (material == null && shader != null)
			{
				material = new Material(shader);
				material.hideFlags = HideFlags.HideAndDontSave;
			}
			return material;
		}
	}
	/* Bloom Ïà¹Ø */
	[System.Serializable]
	public struct BloomSettings
	{
		[Range(0f, 16f)]
		public int maxIterations;
		[Min(1f)]
		public int downscaleLimit;
		[Min(0f)]
		public float threshold;
		[Range(0f, 1f)]
		public float thresholdKnee;
	}

	[SerializeField]
	BloomSettings bloom = default;
	public BloomSettings Bloom => bloom;


}
