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
    //partial void DrawUnsupportedShadersX();//����һ�������� partial ���еĺ���
    public void Render(ScriptableRenderContext context,Camera camera)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();            //ʹ�� command-buffer �����ֺ�cameraһ��
        PrepareForSceneWindow();    //��Cull ֮ǰ��UI
        if (!Cull()) return;
        Setup();
        DrawVisibleGeometry();      //srp shader
        //partial �����ķ���
        DrawUnsupportedShaders();   //�ɹ�����Դ
        DrawGizmos();

        Submit();   //��Ҫ�ύ
    }
    void Setup()
    {
        context.SetupCameraProperties(camera);  //VP ����
        CameraClearFlags flags = camera.clearFlags;
        bool clearDepth = flags <= CameraClearFlags.Depth;
        bool clearColor = flags == CameraClearFlags.Color;
        Color clearC = flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear;
        buffer.ClearRenderTarget(clearDepth, clearColor, clearC);
        buffer.BeginSample(bufferName);         //���� Profiler �� Frame-Debugger
        ExecuteBuffer();
    }
    void DrawVisibleGeometry()
    {
        //����
        var sorttingSettings = new SortingSettings(camera);
        sorttingSettings.criteria = SortingCriteria.CommonOpaque;

        //shader tags
        var drawingSettings = new DrawingSettings(
            unlitShaderTagId, sorttingSettings
            );
        //queue ��Χ
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        //filteringSettings.renderQueueRange = RenderQueueRange.opaque;  ������ôд


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
        context.ExecuteCommandBuffer(buffer);   //���� ָ��
        buffer.Clear();
    }
    bool Cull()
    {
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);   //�޳�����
            return true;
        }
        return false;
    }
}
