using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[CreateAssetMenu(menuName = "Rendering/MyPipelineAsset")]
public class MyPipelineAsset : UniversalRenderPipelineAsset// RenderPipelineAsset
{
    //����һ�� ��Ⱦ����
    protected override RenderPipeline CreatePipeline()
    {
        return new MyRenderPipeline(this);
    }


}

