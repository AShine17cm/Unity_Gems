using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender
{
    partial void DrawGizmos();
    partial void DrawUnsupportedShaders();
    partial void PrepareForSceneWindow();       //在 Scene视口画 UI
    partial void PrepareBuffer();               //使得 command-buffer 的名字和camera一致

#if UNITY_EDITOR
    static Material errorMaterial;

    //旧管线 用的LightMode
    static ShaderTagId[] legacyShaderTagIds =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("ForwardAdd"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };
    //旧管线的 材质
    partial void DrawUnsupportedShaders()
    {
        if(errorMaterial==null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        };

        var drawigSettings = new DrawingSettings
        (
            legacyShaderTagIds[0], new SortingSettings(camera)
        )
        {
            overrideMaterial = errorMaterial
        };

        //设定多个 shader tag
        for(int i=1;i<legacyShaderTagIds.Length;i++)
        {
            drawigSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }
        var filteringSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(cullingResults, ref drawigSettings, ref filteringSettings);

    }
    partial void DrawGizmos()
    {
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }
    //画 UI
    partial void PrepareForSceneWindow()
    {
        if (camera.cameraType == CameraType.SceneView)
        {
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
    }
    partial void PrepareBuffer()
    {
        buffer.name = camera.name;
    }
#endif
}
