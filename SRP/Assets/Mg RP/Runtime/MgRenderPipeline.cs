using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
/*
 主要是 Render: 相机的栈
将渲染外包给 CameraRender
 */
public class MgRenderPipeline : RenderPipeline
{
    CameraRender renderer = new CameraRender();// first-person, 3D-Map,forward,deferred
    bool useDynamicBatching, useGPUInstancing;

    PostFXSettings postFXSettings;

    public MgRenderPipeline(
        bool useDynamicBatching, 
        bool useGPUInstancing, 
        bool useSRPBatcher,
        PostFXSettings postFXSettings)
    {
        this.postFXSettings = postFXSettings;
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;

        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;    //开启 SRP Batcher
        GraphicsSettings.lightsUseLinearIntensity = true;
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach(Camera camera in cameras)
        {
            renderer.Render(context, camera,
                useDynamicBatching,
                useGPUInstancing,
                postFXSettings);
        }
    }

}
