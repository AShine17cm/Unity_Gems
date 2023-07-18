using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Hiz_Helper : MonoBehaviour
{
    public Texture2D inputTex;
    public ComputeShader downscaleCS;
    public RenderTexture outputRT;
    public bool doTest = false;

    int K_downscale;
    int p_RTSize;
    int p_inputRT;
    int p_outputRT;
    public int w, h;

    public int targetW, targetH;
    void Start()
    {
        K_downscale = downscaleCS.FindKernel("Downscale");
        p_RTSize = Shader.PropertyToID("RTSize");
        p_inputRT = Shader.PropertyToID("inputRT");
        p_outputRT = Shader.PropertyToID("outputRT");

        w = inputTex.width;
        h = inputTex.height;
        int mip = 1;
        outputRT = new RenderTexture(w/2, h/2, 1,RenderTextureFormat.Depth,mip);
    }

    // Update is called once per frame
    void Update()
    {
        if (doTest)
        {
            doTest = false;
            targetW = Mathf.Max(1, w / 2);
            targetH = Mathf.Max(1, h / 2);
            downscaleCS.SetVector(p_RTSize, new Vector4(targetW, targetH, 0, 0));
            downscaleCS.SetTexture(K_downscale, p_inputRT, inputTex);
            downscaleCS.SetTexture(K_downscale, p_outputRT, outputRT);

            int x = Mathf.Max(1, targetW / 8);
            int y = Mathf.Max(1, targetH / 8);
            downscaleCS.Dispatch(K_downscale, x, y, 1);
        }

        if (Input.GetKeyUp(KeyCode.F))
        {
            RequestReadbacks();
        }
    }

    Texture2D physicsReadback;
    string rtFileName;
    void RequestReadbacks()
    {
        string post = "_0.png";
        string path = Application.dataPath + "/Compute Culling/";
        physicsReadback = new Texture2D(targetW, targetH, TextureFormat.RGBAFloat, false);
        rtFileName = path + "_mip" + post;
        AsyncGPUReadback.Request(outputRT, 0, TextureFormat.RGBAFloat, OnCompleteReadback);  //displace

    }
    void OnCompleteReadback(AsyncGPUReadbackRequest request) => OnCompleteReadback(request, physicsReadback);

    void OnCompleteReadback(AsyncGPUReadbackRequest request, Texture2D result)
    {
        if (request.hasError)
        {
            return;
        }
        if (result != null)
        {
            result.LoadRawTextureData(request.GetData<Color>());
            result.Apply();

            byte[] bytes = result.EncodeToPNG();
            System.IO.File.WriteAllBytes(rtFileName, bytes);
        }
    }
}
