using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class Shadows 
{
    const int maxShadowedDirectionalLightCount = 1;
    const string bufferName = "Shadows";
    static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");
    static int dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices");

    CommandBuffer buffer = new CommandBuffer{name = bufferName};

    ScriptableRenderContext context;
    CullingResults cullingResults;
    ShadowSettings settings;

    int ShadowedDirectionalLightCount;
    struct ShadowedDirectionalLight { public int visibleLightIndex; }
    ShadowedDirectionalLight[] shadowedDirLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];
    static Matrix4x4 dirShadowMatrices;

    public void Setup(ScriptableRenderContext context,
    CullingResults cullingResults,
    ShadowSettings settings)
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.settings = settings;
        ShadowedDirectionalLightCount = 0;
    }
    public void ReserveDirectionalShadows(Light light,int visibleLightIndex)
    {
        if (ShadowedDirectionalLightCount < maxShadowedDirectionalLightCount&&
            light.shadows != LightShadows.None && light.shadowStrength > 0f&&
            //�ڵƹ�Ӱ�췶Χ�ڣ��Ƿ���caster
            cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b)
            )
        {
            shadowedDirLights[ShadowedDirectionalLightCount] =
                new ShadowedDirectionalLight
                {
                    visibleLightIndex = visibleLightIndex
                };
            ShadowedDirectionalLightCount += 1;
        }
    }
    public void Render()
    {
        if(ShadowedDirectionalLightCount>0)
        {
            RenderDiretionalShadows();
        }
        else
        {
            //û�еƹ������Ӱ��������һ��Ĭ�ϵ� shadowmap
            buffer.GetTemporaryRT(
                dirShadowAtlasId, 1, 1,
                32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap
            );
        }
    }
    void RenderDiretionalShadows()
    {
        int atlasSize = (int)settings.directional.atlasSize;
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize,32,FilterMode.Bilinear,RenderTextureFormat.Shadowmap);
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.ClearRenderTarget(true, false, Color.clear);
        buffer.BeginSample(bufferName);
        ExecuteBuffer();

        for (int i = 0; i < ShadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, atlasSize);
        }
        buffer.SetGlobalMatrix(dirShadowMatricesId, dirShadowMatrices);//���ƹ�ռ�ľ���
        buffer.EndSample(bufferName);
        ExecuteBuffer();
    }
    void RenderDirectionalShadows(int index,int tileSize)
    {
        ShadowedDirectionalLight light = shadowedDirLights[index];
        ShadowDrawingSettings shadowSettings =new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);//��Ӱ����
        //ƽ�й� û��λ�õ㣬ֻ������ View & Projection Matrices  ƥ���ķ���
        //0,1 �Ǽ�����Ӱ, vector3.zero �� splitRate
        //SplitData �Ǹ�������, CasterӦ��������Culled
        cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
            light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0f,
            out Matrix4x4 viewMatrix, 
            out Matrix4x4 projectionMatrix,
            out ShadowSplitData splitData);

        shadowSettings.splitData = splitData;
        dirShadowMatrices = projectionMatrix * viewMatrix;   //���ƹ�ռ�ľ���
        buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
        ExecuteBuffer();
        context.DrawShadows(ref shadowSettings);
    }
    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }
}
