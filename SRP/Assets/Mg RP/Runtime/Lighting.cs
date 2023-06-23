using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;
//定义在 Light.hlsl 中的一个 CBUFFER
//传递 CullingResults 中的灯光参数
public class Lighting 
{
    const string bufferName = "Lighting";
    const int maxDirLightCount = 4;
    static int 
        dirLightCountId=Shader.PropertyToID("_DirLightCount"),
        dirLightColorId = Shader.PropertyToID("_DirLightColors"),
        dirLightDirectionId = Shader.PropertyToID("_DirLightDirections");
    static Vector4[]
        dirLightColors = new Vector4[maxDirLightCount],
        dirLightDirections = new Vector4[maxDirLightCount];

    CommandBuffer buffer = new CommandBuffer { name = bufferName };

    CullingResults cullingResults;
    public void Setup(ScriptableRenderContext context,CullingResults cullingResults)
    {
        this.cullingResults = cullingResults;

        buffer.BeginSample(bufferName);

        SetupLights();

        buffer.EndSample(bufferName);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    void SetupLights()
    {
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;

        int counter = 0;
        for(int i=0;i<visibleLights.Length;i++)
        {
            VisibleLight visibleLight = visibleLights[i];
            if(LightType.Directional== visibleLight.lightType)
            {
                SetupDirLight(counter, ref visibleLight);
                counter += 1;
                if(counter>=maxDirLightCount)
                {
                    break;
                }
            }
        }
        buffer.SetGlobalInt(dirLightCountId, visibleLights.Length);
        buffer.SetGlobalVectorArray(dirLightColorId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionId, dirLightDirections);
    }
    void SetupDirLight(int index,ref VisibleLight visibleLight)
    {
        dirLightColors[index] = visibleLight.finalColor;
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
    }
}
