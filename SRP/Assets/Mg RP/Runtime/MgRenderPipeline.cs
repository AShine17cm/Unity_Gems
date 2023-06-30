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

    ShadowSettings shadowSettings;
    PostFXSettings postFXSettings;

    public MgRenderPipeline(
        bool useDynamicBatching, 
        bool useGPUInstancing, 
        bool useSRPBatcher,
        ShadowSettings shadowSettings,
        PostFXSettings postFXSettings)
    {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        this.shadowSettings = shadowSettings;
        this.postFXSettings = postFXSettings;

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
                shadowSettings,
                postFXSettings);
        }
    }

}
