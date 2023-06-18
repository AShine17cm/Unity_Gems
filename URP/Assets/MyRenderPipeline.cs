using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class MyRenderPipeline : RenderPipeline
{
    MyPipelineAsset asset; //继承自 urp Asset
    //UniversalRenderPipelineAsset urpAsset;          //默认资源
    public MyRenderPipeline(MyPipelineAsset asset)
    {
        this.asset = asset;
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        
    }

}
