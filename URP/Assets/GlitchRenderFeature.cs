using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlitchRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent RenderPassEvent;
        public LayerMask layerMask;
        public Material glitchMaterial;
        public Material blitMaterial;
        [Header("Glitch")]
        public bool SON = false;
        public Color color = Color.black;
        public float offset = 1f;
        public float small_Offset = 1f;
        public float speed = 1f;
        public float clip = 0.2f;

        [Header("Blit Glitch")]
        public float Intensity = 1f;
    }
    public class GlitchRenderPass : ScriptableRenderPass    //对应vulkan中的图形管线
    {
        private Settings settings;
        private FilteringSettings filterSettings;
        private ProfilingSampler m_ProflingSampler;
        private List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        private RenderTargetHandle tempRT;
        private RenderTargetIdentifier _Source;

        public GlitchRenderPass(Settings settings)
        {
            this.settings = settings;
            filterSettings = new FilteringSettings(RenderQueueRange.opaque, settings.layerMask);
            m_ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
            m_ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
            m_ProflingSampler = new ProfilingSampler("Glitch");
            tempRT.Init("_TempGlitch");
        }
        public void setup(RenderTargetIdentifier source)
        {
            _Source = source;
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor opaqueDesc = cameraTextureDescriptor;
            opaqueDesc.depthBufferBits = 0;
            cmd.GetTemporaryRT(tempRT.id, opaqueDesc, FilterMode.Bilinear);
            //Configure which render target we are drawing to  
            ConfigureTarget(tempRT.Identifier());
            ConfigureClear(ClearFlag.Color, Color.clear);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.name = "Glitch";
            //glitchMaterial  
            if (settings.SON)
                settings.glitchMaterial.EnableKeyword("_SON");
            else
                settings.glitchMaterial.DisableKeyword("_SON");
            settings.glitchMaterial.SetColor("_BaseColor", settings.color);
            settings.glitchMaterial.SetFloat("_Offset", settings.offset);
            settings.glitchMaterial.SetFloat("_SmallOffset", settings.small_Offset);
            settings.glitchMaterial.SetFloat("_Speed", settings.speed);
            settings.glitchMaterial.SetFloat("_Clip", settings.clip);
            //blitMaterial  
            settings.blitMaterial.SetFloat("_Intensity", settings.Intensity);

            using (new ProfilingScope(cmd, m_ProflingSampler))
            {
                SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                DrawingSettings drawingSettings =
                    CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
                drawingSettings.overrideMaterialPassIndex = 0;
                drawingSettings.overrideMaterial = settings.glitchMaterial;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filterSettings);
            }            // Blit tempRT to camera target, using blitMaterial  
            cmd.Blit(tempRT.Identifier(), _Source, settings.blitMaterial, 0);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(tempRT.id);
            base.FrameCleanup(cmd);
        }
    }

    GlitchRenderPass m_ScriptablePass;
    public Settings settings;
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.blitMaterial == null)
            return;

        if (settings.glitchMaterial == null)
            return;
        m_ScriptablePass.setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void Create()
    {
        m_ScriptablePass = new GlitchRenderPass(settings);
        m_ScriptablePass.renderPassEvent = settings.RenderPassEvent;
    }

}
