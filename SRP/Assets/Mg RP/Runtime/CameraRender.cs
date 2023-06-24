using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender
{
    const string bufferName = "Mg: Render Camera";
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
     static ShaderTagId litShaderTagId =new ShaderTagId("MgLit");
    static int frameBufferId= Shader.PropertyToID("_CameraFrameBuffer");

    ScriptableRenderContext context;    //provides a connection to the native engine
    Camera camera;
    CommandBuffer buffer = new CommandBuffer { name = bufferName };
    Lighting lighting = new Lighting();
    PostFXStack postFXStack = new PostFXStack();
    CullingResults cullingResults;

    public void Render(ScriptableRenderContext context,Camera camera,
        bool useDynamicBatching,bool useGPUInstancing,
        PostFXSettings postFXSettings)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();            //Editor: ʹ�� command-buffer �����ֺ�cameraһ��
        PrepareForSceneWindow();    //Editor: ��Cull ֮ǰ��UI
        if (!Cull()) return;
        Setup();                                    //VP ����, Clear Target
        lighting.Setup(context,cullingResults);     //ͨ�� CommandBuffer ���õƹ����� 
        postFXStack.Setup(context, camera, postFXSettings);

        DrawVisibleGeometry(useDynamicBatching,useGPUInstancing);      //srp shader
        //partial �����ķ���
        DrawUnsupportedShaders();   //�ɹ�����Դ

        DrawGizmosBeforeFX();
        if(postFXStack.IsActive)
        {
            postFXStack.Render(frameBufferId);
        }
        DrawGizmosAfterFX();

        //if(postFXStack.IsActive)    //����
        //{
        //    postFXStack.Render(frameBufferId);
        //}
        Cleanup();
        Submit();   //��Ҫ�ύ
    }
    void Setup()
    {
        context.SetupCameraProperties(camera);  //VP ����
        CameraClearFlags flags = camera.clearFlags;
        bool clearDepth = flags <= CameraClearFlags.Depth;
        bool clearColor = flags == CameraClearFlags.Color;
        Color clearC = flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear;
        if(postFXStack.IsActive)//��ȡ���趨Ŀ��֡
        {
            if(flags>CameraClearFlags.Color)
            {
                flags = CameraClearFlags.Color;
            }
            buffer.GetTemporaryRT(frameBufferId, camera.pixelWidth, camera.pixelHeight, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
            buffer.SetRenderTarget(frameBufferId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        }
        buffer.ClearRenderTarget(clearDepth, clearColor, clearC);
        buffer.BeginSample(bufferName);         //���� Profiler �� Frame-Debugger
        ExecuteBuffer();
    }
    void DrawVisibleGeometry(bool useDynamicBatching,bool useGPUInstancing)
    {
        //����
        var sorttingSettings = new SortingSettings(camera);
        sorttingSettings.criteria = SortingCriteria.CommonOpaque;

        //shader tags
        var drawingSettings = new DrawingSettings
            (
            unlitShaderTagId, sorttingSettings
            )
        {
            enableDynamicBatching = useDynamicBatching,         //��̬����
            enableInstancing = useGPUInstancing                 //ʵ����
        };
        drawingSettings.SetShaderPassName(1, litShaderTagId);
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
    void Cleanup()
    {
        if (postFXStack.IsActive)
        {
            buffer.ReleaseTemporaryRT(frameBufferId);
        }
    }

}
