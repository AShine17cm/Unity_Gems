using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Mg Render Pipeline")]
public class MgRenderPipelineAsset : RenderPipelineAsset
{
    [SerializeField]
    bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;
    [SerializeField]
    PostFXSettings postFXSettings = default;

    protected override RenderPipeline CreatePipeline()
    {
        return new MgRenderPipeline(
            useDynamicBatching,
            useGPUInstancing,
            useSRPBatcher,
            postFXSettings);
    }


}
