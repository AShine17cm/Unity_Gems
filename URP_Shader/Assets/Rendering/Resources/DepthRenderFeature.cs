using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Material material = null;

        public LayerMask overRenderLayer;
        //Render Queue的设置
        [Range(1000, 5000)]
        public int overlayQueueMin = 2000;
        [Range(1000, 5000)]
        public int overlayQueueMax = 3000;


    }

    class CustomRenderPass : ScriptableRenderPass
    {
        private DepthRenderFeature.Settings settings;
        string m_ProfilerTag;

        FilteringSettings filtering;

        //用于储存之后申请来的RT的ID
        //public int depthID = 0;
        //-------------------------------------------------------
        //深度缓冲
        // int _depthBufferID;
        // RenderTargetIdentifier depthRT;
        //深度图
        public int _depthMapID = 0;
        RenderTargetIdentifier depthMapRT;
        //-------------------------------------------------------

        public ShaderTagId shaderTag = new ShaderTagId("UniversalForward");

        float maskTimer = 0;
        bool isVisible = false;
        bool hasRT = false;
        public CustomRenderPass(DepthRenderFeature.Settings settings)
        {
            this.settings = settings;

            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = Mathf.Min(settings.overlayQueueMax, settings.overlayQueueMin);
            queue.upperBound = Mathf.Max(settings.overlayQueueMax, settings.overlayQueueMin);

            filtering = new FilteringSettings(queue, settings.overRenderLayer);
            _depthMapID = Shader.PropertyToID("_SelfDepthTexture2");
            depthMapRT = new RenderTargetIdentifier(_depthMapID);
        }

        //[IFix.Patch]
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            if (!isVisible)
            {
                hasRT = false;
                ConfigureClear(ClearFlag.None, Color.white);
                return;
            }
            hasRT = true;
            RenderTextureDescriptor desc = new RenderTextureDescriptor(cameraTextureDescriptor.width / 2, cameraTextureDescriptor.height / 2, RenderTextureFormat.ARGBHalf, 16);
            cmd.GetTemporaryRT(_depthMapID, desc, FilterMode.Point);
            //将这个RT设置为Render Target
            ConfigureTarget(depthMapRT);
            ConfigureClear(ClearFlag.All, Color.white);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //检查是否 近水岸
            maskTimer += Time.deltaTime;
            if (maskTimer >= 0.5f)//0.5秒检查一次
            {
                maskTimer = 0;
                //如果地图未配置Mask，默认开启
                Vector3 camPos = renderingData.cameraData.camera.transform.position;
                isVisible = MapWaterHelper.IsVisible(camPos);
            }
            if (!isVisible || !hasRT) return;

            var draw1 = CreateDrawingSettings(shaderTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw1.overrideMaterial = settings.material;
            draw1.overrideMaterialPassIndex = 0;
            context.DrawRenderers(renderingData.cullResults, ref draw1, ref filtering);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (hasRT)
                cmd.ReleaseTemporaryRT(_depthMapID);
        }
    }

    CustomRenderPass m_OverlayPass;

    public Settings settings = new Settings();
    int layerUI = 0;
    public override void Create()
    {
        //---------------------------------------------------------------
        m_OverlayPass = new CustomRenderPass(settings);

        // Configures where the render pass should be injected.
        m_OverlayPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        //---------------------------------------------------------------
        layerUI= LayerMask.GetMask("UI");
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.material == null)
        {
            Debug.LogWarningFormat("丢失blit材质");
            return;
        }
        if ((renderingData.cameraData.camera.cullingMask & layerUI) != 0)
        {
            return;
        }
        //renderingData.cameraData.renderType == CameraRenderType.Base ||
#if UNITY_EDITOR
        if ( renderingData.cameraData.camera.name == "UICamera" ||renderingData.cameraData.camera.name=="SceneCamera")
#else
        if ( renderingData.cameraData.camera.name == "UICamera")
#endif
        {
            return;
        }

        m_OverlayPass.renderPassEvent = settings.renderPassEvent;

        renderer.EnqueuePass(m_OverlayPass);

    }
}


