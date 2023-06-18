using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[CreateAssetMenu(menuName = "Rendering/MyPipelineAsset")]
public class MyPipelineAsset : UniversalRenderPipelineAsset// RenderPipelineAsset
{
    //返回一个 渲染管线
    protected override RenderPipeline CreatePipeline()
    {
        return new MyRenderPipeline(this);
    }


}

