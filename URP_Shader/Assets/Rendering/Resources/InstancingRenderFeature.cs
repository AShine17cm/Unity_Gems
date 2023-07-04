using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class InstancingRenderFeature : ScriptableRendererFeature
{
    class GrassRenderPass : ScriptableRenderPass
    {
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            #if SC_DEVELOPMENT
            InstancingMgr.Ins.Draw(context, renderingData.cameraData.camera);
            #endif
        }
    }

    private GrassRenderPass _grassRenderPass = new GrassRenderPass();
    public override void Create()
    {
        _grassRenderPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(renderingData.cameraData.renderType != CameraRenderType.Base)
            return;
        renderer.EnqueuePass(_grassRenderPass);
    }
}
