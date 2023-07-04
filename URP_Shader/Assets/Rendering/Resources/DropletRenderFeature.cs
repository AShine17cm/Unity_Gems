using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DropletRenderFeature : ScriptableRendererFeature

{
    [System.Serializable]
    public class UnderWaterSetting
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;

        public LayerMask cullingMask = -1;

        public Material mat;

        public bool isUnderwater;


        public bool enableWetLensEffect = true;
        [Range(0.5f, 3)]
        public float wetLensDuration = 1;
    
    }

    public UnderWaterSetting setting = new UnderWaterSetting();

    class DropletRenderPass : ScriptableRenderPass

    {
        public Material Mat = null;
        public UnderWaterSetting setting;

        private bool isUnderwater => setting.isUnderwater;


        string passTag;
        bool enableWetLensEffect = true;
        float time;
        float wetLensDuration = 1.5f;

        private RenderTargetIdentifier Source { get; set; }


        RenderTargetHandle m_temporaryColorTexture;


        public DropletRenderPass(string passname,UnderWaterSetting setting ,RenderPassEvent evt, Material mat,float wetTime)
        {
            passTag = passname;
            renderPassEvent = evt;
            Mat = mat;
            this.setting = setting;
        
            wetLensDuration = wetTime;

        }



        public void setup(RenderTargetIdentifier src)
        {
            this.Source = src;
   

        }
        //void EnableWetLens(bool Isunderwater)
        //{
        //    if (Isunderwater)
        //    {

        //        Mat.SetFloat("_EnableWetLens", 1);
        //        // time = 0;
        //    }
        //    else
        //    {
        //        Mat.SetFloat("_EnableWetLens", 0);
        //        // time = Mathf.Min(time + Time.deltaTime / wetLensDuration, 1);
        //    }
        //}

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(passTag);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            //EnableWetLens(isUnderwater);
            if (isUnderwater)
            {
                Mat.SetFloat("_EnableWetLens", 1);
                time = 0;
              
            }
            else
            {
                Mat.SetFloat("_EnableWetLens", 0);
                time = Mathf.Min(time + Time.deltaTime / (wetLensDuration), 1);
             
                if (enableWetLensEffect)
                {
                    Mat.SetFloat("_Wetness", 1 - time);
                }
            }


            cmd.GetTemporaryRT(m_temporaryColorTexture.id, opaqueDesc.width, opaqueDesc.height, 32, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            cmd.Blit(Source, m_temporaryColorTexture.id, Mat);
            cmd.Blit(m_temporaryColorTexture.id, Source);

            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放该命令
        }
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_temporaryColorTexture.id);
        
        }
    }


    DropletRenderPass mypass;

    public override void Create()

    {
        mypass = new DropletRenderPass("Droplet", setting,setting.passEvent, setting.mat, setting.wetLensDuration);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)

    {
        if (renderingData.cameraData.renderType == CameraRenderType.Overlay)
        {
            return;
        }
        mypass.setup(renderer.cameraColorTarget);

        renderer.EnqueuePass(mypass);

    }
}