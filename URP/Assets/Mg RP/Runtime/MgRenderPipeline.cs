using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class MgRenderPipeline : RenderPipeline
{
    CameraRender renderer = new CameraRender();// first-person, 3D-Map,forward,deferred
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach(Camera camera in cameras)
        {
            renderer.Render(context, camera);
        }
    }

}
