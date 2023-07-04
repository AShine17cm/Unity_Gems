using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DrawColorFeature : ScriptableRendererFeature
{

    [System.Serializable]
    public class setting
    {
        public Material mymat;

        public Color color = Color.blue;


        public LayerMask layer;

        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;

    }

    public setting mysetting = new setting();

    int solidcolorID;

    class DrawSoildColorPass : ScriptableRenderPass
    {
        setting mysetting = null;

        FilteringSettings filter;
        Material mat;

        DrawColorFeature drawColorFeature = null;
        RenderTargetIdentifier sour;
        public DrawSoildColorPass(setting setting, DrawColorFeature render, RenderTargetIdentifier source)
        {
            mysetting = setting;
            filter = new FilteringSettings(RenderQueueRange.opaque, setting.layer);
            mat = setting.mymat;
          
            mat.SetColor(Shader.PropertyToID("_Soildcolor"), setting.color);
            drawColorFeature = render;
            sour = source;

        }


        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            int temp = Shader.PropertyToID("_Soildcolor");
            RenderTextureDescriptor desc = cameraTextureDescriptor;
            cmd.GetTemporaryRT(temp, desc);
            drawColorFeature.solidcolorID = temp;
            ConfigureTarget(temp);

            ConfigureClear(ClearFlag.All, Color.white);

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            CommandBuffer cmd = CommandBufferPool.Get("DrawColorPass");

            var draw = CreateDrawingSettings(new ShaderTagId("DepthOnly"), ref renderingData,
            renderingData.cameraData.defaultOpaqueSortFlags);
            draw.overrideMaterial = mysetting.mymat;
            draw.overrideMaterialPassIndex = 0;
            context.DrawRenderers(renderingData.cullResults, ref draw, ref filter);

            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            int SourID = Shader.PropertyToID("_SourTex");
            cmd.GetTemporaryRT(SourID, desc);
            cmd.CopyTexture(sour, SourID);

            cmd.Blit(drawColorFeature.solidcolorID, sour, mysetting.mymat);
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }
    }

    DrawSoildColorPass m_DrawSoildColorPass;


    public override void Create()
    {
     
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (mysetting.mymat == null)
        {
            Debug.LogError("材质球丢失！请设置材质球");
            return;
        }
        if (renderingData.cameraData.renderType == CameraRenderType.Overlay && renderingData.cameraData.camera.name == "UICamera")
        {
            return;
        }
            RenderTargetIdentifier sour = renderer.cameraColorTarget;
            m_DrawSoildColorPass = new DrawSoildColorPass(mysetting, this,sour);
            m_DrawSoildColorPass.renderPassEvent = mysetting.passEvent;
            renderer.EnqueuePass(m_DrawSoildColorPass);
          

      
    }

   

}