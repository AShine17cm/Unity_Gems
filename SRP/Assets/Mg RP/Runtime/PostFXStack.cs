using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class PostFXStack 
{
    const string bufferName = "Post Fx";
    int fxSourceId = Shader.PropertyToID("_PostFXSource");
    int fxSource2Id = Shader.PropertyToID("_PostFXSource2");
    int bloomPrefilterId = Shader.PropertyToID("_BloomPrefilter");
    int bloomThresholdId = Shader.PropertyToID("_BloomThreshold");

    CommandBuffer buffer = new CommandBuffer() { name = bufferName };
    ScriptableRenderContext context;
    Camera camera;
    PostFXSettings settings;

    const int maxBloomPyramidLevels = 16;
    int bloomPyramidId;
    enum Pass
    {
        Copy,
        BloomHorizontal,
        BloomVertical,
        BloomCombine,
        BloomPrefilter
    }
    public PostFXStack()
    {
        bloomPyramidId = Shader.PropertyToID("_BloomPyramid0");
        for (int i = 1; i < maxBloomPyramidLevels*2; i++)
        {
            Shader.PropertyToID("_BloomPyramid" + i);//分配，占位 ID
        }
    }
    void DoBloom(int sourceId)
    {
        buffer.BeginSample("Bloom");
        PostFXSettings.BloomSettings bloom = settings.Bloom;
        int width = camera.pixelWidth / 2;
        int height = camera.pixelHeight / 2;
        if(bloom.maxIterations==0||height<bloom.downscaleLimit||width<bloom.downscaleLimit)
        {
            Draw(sourceId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);//不做Bloom
            buffer.EndSample("Bloom");
            return;
        }
        Vector4 threshold;
        threshold.x = Mathf.GammaToLinearSpace(bloom.threshold);
        threshold.y = threshold.x * bloom.thresholdKnee;
        threshold.z = 2f * threshold.y;
        threshold.w = 0.25f / (threshold.y + 0.00001f);
        threshold.y -= threshold.x;
        buffer.SetGlobalVector(bloomThresholdId, threshold);

        RenderTextureFormat format = RenderTextureFormat.Default;
        buffer.GetTemporaryRT(bloomPrefilterId, width, height, 0, FilterMode.Bilinear, format);
        Draw(sourceId, bloomPrefilterId, Pass.BloomPrefilter);

        width /= 2;
        height /= 2;

        int fromId = bloomPrefilterId;
        int toId = bloomPyramidId+1;//第一级别
        int i;
        for(i=0;i<bloom.maxIterations;i++)//拷贝金字塔
        {
            if (height < bloom.downscaleLimit || width < bloom.downscaleLimit) break; //采样最小比例

            int midId = toId - 1;
            buffer.GetTemporaryRT(midId, width, height, 0, FilterMode.Bilinear, format);
            buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, format);
            Draw(fromId, midId, Pass.BloomHorizontal);  //先水平
            Draw(midId, toId, Pass.BloomVertical);      //再垂直,此时UV步长 是2倍
            fromId = toId;
            toId += 2;//前进2步
            width /= 2;
            height /= 2;
        }
        buffer.ReleaseTemporaryRT(bloomPrefilterId);

        //Draw(fromId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);
        if (i > 1)
        {
            buffer.ReleaseTemporaryRT(fromId - 1);
            toId -= 5;

            for (i -= 1; i > 0; i--)
            {
                buffer.SetGlobalTexture(fxSource2Id, toId + 1);
                Draw(fromId, toId, Pass.BloomCombine);

                buffer.ReleaseTemporaryRT(fromId);
                buffer.ReleaseTemporaryRT(toId + 1);
                fromId = toId;
                toId -= 2;
            }
        }
        else
        {
            buffer.ReleaseTemporaryRT(bloomPyramidId);
        }
        buffer.SetGlobalTexture(fxSource2Id, sourceId);
        Draw(fromId, BuiltinRenderTextureType.CameraTarget, Pass.BloomCombine);
        buffer.ReleaseTemporaryRT(fromId);

        buffer.EndSample("Bloom");
    }
    public bool IsActive => settings != null;
    public void Setup(ScriptableRenderContext context, Camera camera, PostFXSettings settings)
    {
        this.context = context;
        this.camera = camera;
        //this.settings = settings;
        this.settings = camera.cameraType <= CameraType.SceneView ? settings : null;
        ApplySceneViewState();//是否禁用
    }
    public void Render(int sourceId)
    {
        //buffer.Blit(sourceId, BuiltinRenderTextureType.CameraTarget);
        //Draw(sourceId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);
        DoBloom(sourceId);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();                                                                                                                                                                          
    }

    //后处理
   void Draw(RenderTargetIdentifier from,RenderTargetIdentifier to,Pass pass)
    {
        buffer.SetGlobalTexture(fxSourceId, from);
        buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int)pass, MeshTopology.Triangles, 3);
    }
}
