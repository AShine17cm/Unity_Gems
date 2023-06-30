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
            //在灯光影响范围内，是否有caster
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
            //没有灯光产生阴影，就生成一个默认的 shadowmap
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
        buffer.SetGlobalMatrix(dirShadowMatricesId, dirShadowMatrices);//到灯光空间的矩阵
        buffer.EndSample(bufferName);
        ExecuteBuffer();
    }
    void RenderDirectionalShadows(int index,int tileSize)
    {
        ShadowedDirectionalLight light = shadowedDirLights[index];
        ShadowDrawingSettings shadowSettings =new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);//阴影设置
        //平行光 没有位置点，只能设置 View & Projection Matrices  匹配光的方向
        //0,1 是级联阴影, vector3.zero 是 splitRate
        //SplitData 是个包裹球, Caster应该怎样被Culled
        cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
            light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0f,
            out Matrix4x4 viewMatrix, 
            out Matrix4x4 projectionMatrix,
            out ShadowSplitData splitData);

        shadowSettings.splitData = splitData;
        dirShadowMatrices = projectionMatrix * viewMatrix;   //到灯光空间的矩阵
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
