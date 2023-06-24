using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender
{
    partial void DrawGizmosBeforeFX();
    partial void DrawGizmosAfterFX();
    partial void DrawUnsupportedShaders();
    partial void PrepareForSceneWindow();       //�� Scene�ӿڻ� UI
    partial void PrepareBuffer();               //ʹ�� command-buffer �����ֺ�cameraһ��

#if UNITY_EDITOR
    static Material errorMaterial;

    //�ɹ��� �õ�LightMode
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
    //�ɹ��ߵ� ����
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

        //�趨��� shader tag
        for(int i=1;i<legacyShaderTagIds.Length;i++)
        {
            drawigSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }
        var filteringSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(cullingResults, ref drawigSettings, ref filteringSettings);

    }
    partial void DrawGizmosBeforeFX()
    {
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            //context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }
    partial void DrawGizmosAfterFX()
    {
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }
    
    //�� UI
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
