using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class MyRenderPipeline : RenderPipeline
{
    MyPipelineAsset asset; //�̳��� urp Asset
    //UniversalRenderPipelineAsset urpAsset;          //Ĭ����Դ
    public MyRenderPipeline(MyPipelineAsset asset)
    {
        this.asset = asset;
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        
    }

}
