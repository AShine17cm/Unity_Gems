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
    static int dirLightCountId = Shader.PropertyToID("_DirLightCount");
    static int dirLightColorId = Shader.PropertyToID("_DirLightColors");
    static int dirLightDirectionId = Shader.PropertyToID("_DirLightDirections");
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
    static Vector4[] dirLightDirections = new Vector4[maxDirLightCount];

    CommandBuffer buffer = new CommandBuffer { name = bufferName };
    CullingResults cullingResults;
    Shadows shadows = new Shadows();
    public void Setup(ScriptableRenderContext context,
        CullingResults cullingResults,
        ShadowSettings shadowSettings)
    {
        this.cullingResults = cullingResults;

        buffer.BeginSample(bufferName);
        shadows.Setup(context, cullingResults, shadowSettings); //阴影
        SetupLights();
        shadows.Render();

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
        shadows.ReserveDirectionalShadows(visibleLight.light, index);   //产生阴影的灯光 ?
    }
    public void Cleanup()
    {
        shadows.Cleanup();
    }
}
