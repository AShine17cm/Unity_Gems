using System;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    public float shadowDistance = 100f;
    public Directional directional = new Directional { atlasSize = TextureSize._1024 };
    [System.Serializable]
    public struct Directional
    {
        public TextureSize atlasSize;
    }
    public enum TextureSize
    {
        _256=256,_512=512,_1024=1024,_2048=2048
    }

}
