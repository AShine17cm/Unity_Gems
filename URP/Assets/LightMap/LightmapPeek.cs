using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightmapPeek : MonoBehaviour
{
    public Renderer render;
    public int lm_index;
    public Vector4 lm_offset;
    // Start is called before the first frame update
    void Start()
    {
        lm_index = render.lightmapIndex;
        lm_offset = render.lightmapScaleOffset;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
