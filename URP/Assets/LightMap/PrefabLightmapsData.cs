using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEditor;

[DisallowMultipleComponent]

[ExecuteInEditMode]

public class PrefabLightmapsData : MonoBehaviour
{
    [System.Serializable]
    struct RendererInfo
    {
        public Terrain terrain;
        public Renderer renderer;
        public int lightmapIndex;
        public Vector4 lightmapOffsetScale;
    }

    [SerializeField]
    RendererInfo[] m_RendererInfo;
    [SerializeField]
    Texture2D[] m_LightmapsColor;
    [SerializeField]
    Texture2D[] _lightmaps;

    //运行时 设置
    void Awake()
    {
        if (m_RendererInfo == null || m_RendererInfo.Length == 0)
            return;
        var lightmaps = LightmapSettings.lightmaps;
        var combinedLightmaps = new LightmapData[lightmaps.Length + m_LightmapsColor.Length];
        lightmaps.CopyTo(combinedLightmaps, 0);
        //追加 Prefab上的 LM
        for (int i = 0; i < m_LightmapsColor.Length; i++)
        {
            combinedLightmaps[i + lightmaps.Length] = new LightmapData();
            combinedLightmaps[i + lightmaps.Length].lightmapColor = m_LightmapsColor[i];
            combinedLightmaps[i + lightmaps.Length].lightmapDir = _lightmaps[i];
        }
        ApplyRendererInfo(m_RendererInfo, lightmaps.Length);
        LightmapSettings.lightmaps = combinedLightmaps;
    }

    static void ApplyRendererInfo(RendererInfo[] infos, int lightmapOffsetIndex)
    {
        for (int i = 0; i < infos.Length; i++)
        {
            var info = infos[i];
            if (info.renderer != null)
            {
                info.renderer.lightmapIndex = info.lightmapIndex + lightmapOffsetIndex;
                info.renderer.lightmapScaleOffset = info.lightmapOffsetScale;
            }
            else if (info.terrain != null)
            {
                info.terrain.lightmapIndex = info.lightmapIndex + lightmapOffsetIndex;
                info.terrain.lightmapScaleOffset = info.lightmapOffsetScale;
            }
        }
    }

#if UNITY_EDITOR
    [UnityEditor.MenuItem("Tools/Bake Prefab Lightmaps")]
    static void GenerateLightmapInfo()
    {
        if (UnityEditor.Lightmapping.giWorkflowMode != UnityEditor.Lightmapping.GIWorkflowMode.OnDemand)
        {
            Debug.LogError("操作错误,提取信息需要禁用Auto模式 \n ExtractLightmapData requires that you have baked you lightmaps and Auto mode is disabled.");
            return;
        }
        UnityEditor.Lightmapping.Bake();
        PrefabLightmapsData[] prefabs = GameObject.FindObjectsOfType<PrefabLightmapsData>();
        foreach (var instance in prefabs)
        {
            var gameObject = instance.gameObject;
            var rendererInfos = new List<RendererInfo>();
            var lightmapsColor = new List<Texture2D>();
            List<Texture2D> lightmapsDir = new List<Texture2D>();
            GenerateLightmapInfo(gameObject, rendererInfos, lightmapsColor, lightmapsDir);
            instance.m_RendererInfo = rendererInfos.ToArray();
            instance.m_LightmapsColor = lightmapsColor.ToArray();
            instance._lightmaps = lightmapsDir.ToArray();
            var targetPrefab = PrefabUtility.GetCorrespondingObjectFromOriginalSource(instance.gameObject) as GameObject;
            if (targetPrefab != null)
            {
                GameObject root = PrefabUtility.GetOutermostPrefabInstanceRoot(instance.gameObject);
                if (root != null)
                {
                    GameObject rootPrefab = PrefabUtility.GetCorrespondingObjectFromSource(instance.gameObject);
                    string rootPath = AssetDatabase.GetAssetPath(rootPrefab);
                    PrefabUtility.UnpackPrefabInstanceAndReturnNewOutermostRoots(root, PrefabUnpackMode.OutermostRoot);
                    try
                    {
                        PrefabUtility.ApplyPrefabInstance(instance.gameObject, InteractionMode.AutomatedAction);
                    }
                    catch { }
                    finally
                    {
                        PrefabUtility.SaveAsPrefabAssetAndConnect(root, rootPath, InteractionMode.AutomatedAction);
                    }
                }
                else
                {
                    PrefabUtility.ApplyPrefabInstance(instance.gameObject, InteractionMode.AutomatedAction);
                }
            }
        }
    }

    static void GenerateLightmapInfo(GameObject root, List<RendererInfo> rendererInfos, List<Texture2D> lightmapsColor, List<Texture2D> lightmapsDir)
    {
        var renderers = root.GetComponentsInChildren<MeshRenderer>();
        //收集 render上的 LM 信息
        foreach (MeshRenderer renderer in renderers)
        {
            if (renderer.lightmapIndex != -1)
            {
                RendererInfo info = new RendererInfo();
                info.renderer = renderer;
                if (renderer.lightmapScaleOffset != Vector4.zero)
                {
                    info.lightmapOffsetScale = renderer.lightmapScaleOffset;
                    Texture2D lightmapColor = LightmapSettings.lightmaps[renderer.lightmapIndex].lightmapColor;
                    Texture2D lightmapDir = LightmapSettings.lightmaps[renderer.lightmapIndex].lightmapDir;
                    info.lightmapIndex = lightmapsColor.IndexOf(lightmapColor);
                    if (info.lightmapIndex == -1)
                    {
                        info.lightmapIndex = lightmapsColor.Count;
                        lightmapsColor.Add(lightmapColor);
                        lightmapsDir.Add(lightmapDir);
                    }
                    rendererInfos.Add(info);
                }
            }
        }
        var Terrainrenderers = root.GetComponentsInChildren<Terrain>();
        //收集 terrain上的 LM 信息
        foreach (var terrain in Terrainrenderers)
        {
            if (terrain.lightmapIndex != -1)
            {
                RendererInfo info = new RendererInfo();
                info.terrain = terrain;
                if (terrain.lightmapScaleOffset != Vector4.zero)
                {
                    info.lightmapOffsetScale = terrain.lightmapScaleOffset;
                    Texture2D lightmapColor = LightmapSettings.lightmaps[terrain.lightmapIndex].lightmapColor;
                    Texture2D lightmapDir = LightmapSettings.lightmaps[terrain.lightmapIndex].lightmapDir;
                    info.lightmapIndex = lightmapsColor.IndexOf(lightmapColor);
                    if (info.lightmapIndex == -1)
                    {
                        info.lightmapIndex = lightmapsColor.Count;
                        lightmapsColor.Add(lightmapColor);
                        lightmapsDir.Add(lightmapDir);
                    }
                    rendererInfos.Add(info);
                }
            }
        }
    }
#endif

}
