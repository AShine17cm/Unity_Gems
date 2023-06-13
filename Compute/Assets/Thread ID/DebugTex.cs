using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DebugTex : MonoBehaviour
{
    struct VecMatrix
    {
        Vector3 pos;
        Matrix4x4 matrix;
    }
    public int id;
    public ComputeShader compute;
    public RenderTexture rdTex;
    void Run()
    {
        rdTex = new RenderTexture(256, 256, 4);
        rdTex.enableRandomWrite = true;
        rdTex.Create();

        int k_Main = compute.FindKernel("CSMain");

        compute.SetTexture(k_Main, "Result", rdTex);
        compute.Dispatch(k_Main, 256 / 8, 256 / 8, 1);  //32 * 32 个 work group, 不能相互通信

        //第二个 kernel
        VecMatrix[] buffer = new VecMatrix[5];
        ComputeBuffer cpBuffer = new ComputeBuffer(buffer.Length, 3*4+16*4);//需要指定 buffer大小
        cpBuffer.SetData(buffer);

        int k_Multi = compute.FindKernel("Multiply");
        compute.SetBuffer(k_Multi, "dataBuffer", cpBuffer);
        compute.Dispatch(k_Multi, buffer.Length, 1, 1);
    }
    
    void Start()
    {
        Run();
        id = gameObject.GetInstanceID();
    }

    
    void Update()
    {
        
    }
}
