using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DistortRenderFeature : ScriptableRendererFeature

{
    [System.Serializable]
    public class UnderWaterSetting 
    {
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents; 
      
        public LayerMask cullingMask = -1;

        public Material[] mat;

        [Range(0, 0.1f)]
        public float distortionStrength = 0.025f;

        [Range(0, 1f)]
        public float lerpDistort = 0.025f;

        [Range(2, 10)] 
        public int downsample = 2;

        [Range(2, 10)] 
        public int loop = 2;

        [Range(0.01f, 5)]
        public float blur = 0.5f;

    }

    public UnderWaterSetting setting = new UnderWaterSetting();

    class UnderWaterDistortRenderPass : ScriptableRenderPass 

    {
        public Material Mat = null;


        public FilterMode passfiltermode { get; set; } 

        private RenderTargetIdentifier Source { get; set; } 
        private RenderTargetHandle dest { get; set; } 

        RenderTargetHandle m_temporaryColorTexture;

        string passTag;

        public UnderWaterDistortRenderPass(string passname, RenderPassEvent evt, Material mat, float distortionStrength, float lerpDistort) 
        {
            passTag = passname;
            renderPassEvent = evt;
            Mat = mat;
            Mat.SetFloat("_Distortion", distortionStrength);
            Mat.SetFloat("_LerpDistort", lerpDistort);

           
        }

      
            
        public void setup(RenderTargetIdentifier src, RenderTargetHandle destination) 
        {
            this.Source = src;
            this.dest = destination;
          
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) 
        {
            CommandBuffer cmd = CommandBufferPool.Get(passTag);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;

            if (dest==RenderTargetHandle.CameraTarget)
            {
            cmd.GetTemporaryRT(m_temporaryColorTexture.id, opaqueDesc.width,opaqueDesc.height,32, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            
            cmd.Blit(Source, m_temporaryColorTexture.id, Mat);
            cmd.Blit(m_temporaryColorTexture.id, Source);
            }
            else
            {
                cmd.Blit(Source, dest.id, Mat);
            }
         

           
         
            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放该命令
        }
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_temporaryColorTexture.id);
          //  RenderTexture.ReleaseTemporary(mask);
        }
    }

    class UnderWaterBlurRenderPass : ScriptableRenderPass 

    {
        public Material passMat = null;


        public int passdownsample = 2;

        public int passloop = 2;

        public float passblur = 4;


        public FilterMode passfiltermode { get; set; }

        private RenderTargetIdentifier Source { get; set; } 
        RenderTargetHandle buffer1; 
        RenderTargetHandle buffer2;

        string passTag;

        public UnderWaterBlurRenderPass(string passname, RenderPassEvent evt, Material mat,float blur,int loop,int downsample) 
        {
            passTag = passname;
            buffer1.Init(("bufferblur1"));
            buffer2.Init(("bufferblur2"));
            renderPassEvent = evt;
            passMat = mat;
            passblur = blur;
            passloop = loop;
            passdownsample = downsample;
        }



        public void setup(RenderTargetIdentifier src) 
        {
            this.Source = src;
         
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) //类似OnRenderimagePass
        {
            CommandBuffer cmd = CommandBufferPool.Get(passTag);

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            int width = opaqueDesc.width / passdownsample;
            int height = opaqueDesc.height / passdownsample;

            opaqueDesc.depthBufferBits = 0;

            cmd.GetTemporaryRT(buffer1.id, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            cmd.GetTemporaryRT(buffer2.id, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            cmd.SetGlobalFloat("_KawaseBlur", 1f);
            cmd.Blit(Source, buffer1.id, passMat);

            for (int t = 1; t < passloop; t++)
            {
                cmd.SetGlobalFloat("_KawaseBlur", t * passblur + 1);
                cmd.Blit(buffer1.id, buffer2.id, passMat);

                var temRT = buffer1;
                buffer1 = buffer2;
                buffer2 = temRT;
            }

            cmd.SetGlobalFloat("_KawaseBlur", passloop * passblur + 1);
            cmd.Blit(buffer1.id, Source, passMat);

            cmd.ReleaseTemporaryRT(buffer1.id);
            cmd.ReleaseTemporaryRT(buffer2.id);

            context.ExecuteCommandBuffer(cmd); //执行命令缓冲区的该命令
            CommandBufferPool.Release(cmd); //释放该命令
        }
  
    }
    UnderWaterDistortRenderPass mypass;
    UnderWaterBlurRenderPass blurpass;
    public override void Create() 

    {
        mypass = new UnderWaterDistortRenderPass("underWaterDistort",setting.passEvent,setting.mat[0], setting.distortionStrength,setting.lerpDistort);
        blurpass = new UnderWaterBlurRenderPass("underWaterblur",setting.passEvent,setting.mat[1],setting.blur,setting.loop,setting.downsample);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) 

    {

        var src = renderer.cameraColorTarget;
        var dest = RenderTargetHandle.CameraTarget;
        if (setting.mat == null)
        {
            Debug.LogWarningFormat("丢失blit材质");
            return;
        }
        if (renderingData.cameraData.renderType == CameraRenderType.Overlay && renderingData.cameraData.camera.name== "UICamera")
        {
            return;
        }
        mypass.setup(src, dest);
        blurpass.setup(src);
        renderer.EnqueuePass(mypass);
        renderer.EnqueuePass(blurpass);
    }
}