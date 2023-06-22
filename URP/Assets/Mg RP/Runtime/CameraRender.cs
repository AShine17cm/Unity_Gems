using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender
{
    const string bufferName = "Mg: Render Camera";
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");

    ScriptableRenderContext context;    //provides a connection to the native engine
    Camera camera;
    CommandBuffer buffer = new CommandBuffer { name = bufferName };
    CullingResults cullingResults;
    //partial void DrawUnsupportedShadersX();//声明一个存在于 partial 类中的函数
    public void Render(ScriptableRenderContext context,Camera camera)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();            //使得 command-buffer 的名字和camera一致
        PrepareForSceneWindow();    //在Cull 之前画UI
        if (!Cull()) return;
        Setup();
        DrawVisibleGeometry();      //srp shader
        //partial 声明的方法
        DrawUnsupportedShaders();   //旧管线资源
        DrawGizmos();

        Submit();   //需要提交
    }
    void Setup()
    {
        context.SetupCameraProperties(camera);  //VP 矩阵
        CameraClearFlags flags = camera.clearFlags;
        bool clearDepth = flags <= CameraClearFlags.Depth;
        bool clearColor = flags == CameraClearFlags.Color;
        Color clearC = flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear;
        buffer.ClearRenderTarget(clearDepth, clearColor, clearC);
        buffer.BeginSample(bufferName);         //用于 Profiler 和 Frame-Debugger
        ExecuteBuffer();
    }
    void DrawVisibleGeometry()
    {
        //排序
        var sorttingSettings = new SortingSettings(camera);
        sorttingSettings.criteria = SortingCriteria.CommonOpaque;

        //shader tags
        var drawingSettings = new DrawingSettings(
            unlitShaderTagId, sorttingSettings
            );
        //queue 范围
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        //filteringSettings.renderQueueRange = RenderQueueRange.opaque;  不能这么写


        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);

        sorttingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sorttingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;

        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
    void Submit()
    {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);   //拷贝 指令
        buffer.Clear();
    }
    bool Cull()
    {
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);   //剔除操作
            return true;
        }
        return false;
    }
}
