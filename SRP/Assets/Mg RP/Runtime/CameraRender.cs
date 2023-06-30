using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/* 创建 命名的Command Buffer 用于渲染，调试 */
public partial class CameraRender
{
    const string bufferName = "Mg: Render Camera";
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    static ShaderTagId litShaderTagId =new ShaderTagId("MgLit");
    static ShaderTagId lit2ShaderTagId = new ShaderTagId("MgLit2");
    static ShaderTagId urpShaderTagId = new ShaderTagId("UniversalForward");//?
    static int frameBufferId= Shader.PropertyToID("_CameraFrameBuffer");// display或者 预定义的RT  无法控制

    ScriptableRenderContext context;    //provides a connection to the native engine
    Camera camera;
    CommandBuffer buffer = new CommandBuffer { name = bufferName };
    Lighting lighting = new Lighting();
    PostFXStack postFXStack = new PostFXStack();
    CullingResults cullingResults;

    public void Render(ScriptableRenderContext context,Camera camera,
        bool useDynamicBatching,
        bool useGPUInstancing,
        ShadowSettings shadowSettings,
        PostFXSettings postFXSettings)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();            //Editor: 使得 command-buffer 的名字和camera一致
        PrepareForSceneWindow();    //Editor: 在Cull 之前画UI
        if (!Cull(shadowSettings.shadowDistance)) return;

        buffer.BeginSample("SampleName");
        ExecuteBuffer();
        lighting.Setup(context,cullingResults,shadowSettings);  //通过 CommandBuffer 设置灯光数据 
        buffer.EndSample("SampleName");

        Setup();                                                //VP 矩阵, Clear Target
        postFXStack.Setup(context, camera, postFXSettings);

        DrawVisibleGeometry(useDynamicBatching,useGPUInstancing);      //srp shader
        //partial 声明的方法
        DrawUnsupportedShaders();   //旧管线资源

        DrawGizmosBeforeFX();
        if(postFXStack.IsActive)
        {
            postFXStack.Render(frameBufferId);
        }
        DrawGizmosAfterFX();

        //if(postFXStack.IsActive)    //后处理
        //{
        //    postFXStack.Render(frameBufferId);
        //}
        Cleanup();
        Submit();   //需要提交
    }
    void Setup()
    {
        context.SetupCameraProperties(camera);  //VP 矩阵
        CameraClearFlags flags = camera.clearFlags;
        bool clearDepth = flags <= CameraClearFlags.Depth;
        bool clearColor = flags == CameraClearFlags.Color;
        Color clearC = flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear;
        //_CameraFrameBuffer  无法控制,需要提供一个中间的RT 用作postFX的source
        if (postFXStack.IsActive)//获取，设定目标帧
        {
            if(flags>CameraClearFlags.Color)
            {
                flags = CameraClearFlags.Color;
            }
            buffer.GetTemporaryRT(frameBufferId, camera.pixelWidth, camera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
            buffer.SetRenderTarget(frameBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        }

        buffer.ClearRenderTarget(clearDepth, clearColor, clearC);
        buffer.BeginSample(bufferName);         //用于 Profiler 和 Frame-Debugger
        ExecuteBuffer();
    }
    void DrawVisibleGeometry(bool useDynamicBatching,bool useGPUInstancing)
    {
        //排序
        var sorttingSettings = new SortingSettings(camera);
        sorttingSettings.criteria = SortingCriteria.CommonOpaque;

        //shader tags
        var drawingSettings = new DrawingSettings
            (
           unlitShaderTagId , sorttingSettings
            )
        {
            enableDynamicBatching = useDynamicBatching,         //动态合批
            enableInstancing = useGPUInstancing,                 //实例化
            perObjectData= PerObjectData.Lightmaps
        };
        drawingSettings.SetShaderPassName(1, litShaderTagId);
        drawingSettings.SetShaderPassName(2, lit2ShaderTagId);   
        //drawingSettings.SetShaderPassName(3, urpShaderTagId);   //兼容 URP
        //queue 范围
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        //filteringSettings.renderQueueRange = RenderQueueRange.opaque;  不能这么写

        //不透明
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);

        //透明物体
        sorttingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sorttingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        //drawingSettings.SetShaderPassName(1, unlitShaderTagId); 
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
    void Submit()
    {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        lighting.Cleanup();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);   //拷贝 指令
        buffer.Clear();
    }
    bool Cull(float shadowDistance)
    {
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            p.shadowDistance = shadowDistance;      //阴影距离
            cullingResults = context.Cull(ref p);   //剔除操作
            return true;
        }
        return false;
    }
    void Cleanup()
    {
        if (postFXStack.IsActive)
        {
            buffer.ReleaseTemporaryRT(frameBufferId);
        }
    }

}
