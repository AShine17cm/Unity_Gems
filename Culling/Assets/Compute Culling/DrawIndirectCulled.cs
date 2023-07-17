using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class DrawIndirectCulled : MonoBehaviour
{
    //传递到 CS shader的数据
    public struct ObjInfo
    {
        public int id;
        public Vector3 boundMin;
        public Vector3 boundMax;
        public Matrix4x4 localToWorldMatrix;
        public Matrix4x4 worldToLocalMatrix;
    }
    //计算得到的可见数据
    public struct MatrixInfo
    {
        public int id;
        public Matrix4x4 localToWorldMatrix;
        public Matrix4x4 worldToLocalMatrix;
    }
    public bool drawInsatnced;
    public bool hideByFrustrum;
    public int instanceCount;
    public int visibleCount;                        //可见的计数
    public Mesh instanceMesh;
    public Material instanceMaterial;
    public ComputeShader compute;
    public Camera cam;
    ComputeBuffer posBuffer;
    ComputeBuffer argsBuffer;
    ComputeBuffer cullResult;
    ComputeBuffer counterBuffer;                    //计数的读回
    int[] counter = new int[1];                     //计数的读回
    MatrixInfo[] readBack = new MatrixInfo[1024];   //可见数据的读回
    public GameObject gx;
    public int gx_id;
    List<GameObject> goes = new List<GameObject>(1024);
    List<ObjInfo> infos = new List<ObjInfo>(1024);
    uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    int kernel;

    void Start()
    {
        kernel = compute.FindKernel("CSMain");
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        cullResult = new ComputeBuffer(1024, sizeof(float) * (32 + 1), ComputeBufferType.Append);
        counterBuffer = new ComputeBuffer(1, sizeof(int) * 1, ComputeBufferType.IndirectArguments);
        gx_id = gx.GetInstanceID();
    }


    // Update is called once per frame
    void Update()
    {
        UpdateBuffers();

        posBuffer.SetData(infos);
        compute.SetBuffer(kernel, "input", posBuffer);

        cullResult.SetCounterValue(0);
        compute.SetBuffer(kernel, "cullResult", cullResult);

        compute.SetInt("instanceCount", instanceCount);
        compute.SetFloat("aspect", cam.aspect);
        Matrix4x4 vp = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false) * cam.worldToCameraMatrix;
        //Matrix4x4 vp = cam.projectionMatrix * cam.worldToCameraMatrix;
        compute.SetMatrix("vpMatrix", vp);

        int groups = instanceCount / 64;
        if (instanceCount % 64 > 0) groups += 1;
        compute.Dispatch(kernel, groups, 1, 1);

        //读回数据
        ComputeBuffer.CopyCount(cullResult, counterBuffer, 0);
        counterBuffer.GetData(counter);
        cullResult.GetData(readBack);
        visibleCount = counter[0];

        //将可见数据画出
        if (drawInsatnced)
        {
            instanceMaterial.SetBuffer("posBuffer", cullResult);
            int submeshIndex = 0;
            args[0] = (uint)instanceMesh.GetIndexCount(submeshIndex);
            args[1] = (uint)counter[0];
            args[2] = (uint)instanceMesh.GetIndexStart(submeshIndex);
            args[3] = (uint)instanceMesh.GetBaseVertex(submeshIndex);
            argsBuffer.SetData(args);

            Graphics.DrawMeshInstancedIndirect(instanceMesh, submeshIndex, instanceMaterial,
                new Bounds(Vector3.zero, new Vector3(300, 300, 300)),
                argsBuffer);
        }
        if(hideByFrustrum)
        {
            Apply(goes);
        }
    }
    void UpdateBuffers()
    {
        infos.Clear();
        //收集场景数据
        SceneHelper.Collect(goes);
        for (int i = 0; i < goes.Count; i++)
        {
            Transform tr = goes[i].transform;
            Renderer render = tr.GetComponent<Renderer>();
            ObjInfo info = new ObjInfo
            {
                id = goes[i].GetInstanceID(),
                boundMin = render.bounds.min,
                boundMax = render.bounds.max,
                localToWorldMatrix = tr.localToWorldMatrix,
                worldToLocalMatrix = tr.worldToLocalMatrix
            };
            infos.Add(info);
        }
        instanceCount = infos.Count;
        if (posBuffer != null) { posBuffer.Release(); }
        //if (cullResult != null) { cullResult.Release(); }

        posBuffer = new ComputeBuffer(instanceCount, sizeof(float) * (16 + 16 + 6 + 1));
        //cullResult = new ComputeBuffer(instanceCount, sizeof(float) * (32 + 1), ComputeBufferType.Append);
    }
    void Apply(List<GameObject> goes)
    {
        //粗略的视野范围

        Scene scene = SceneManager.GetActiveScene();
        goes.Clear();
        scene.GetRootGameObjects(goes);
        //先全关掉
        for (int k = 0; k < goes.Count; k++)
        {
            GameObject go = goes[k];
            if (go.GetComponent<MeshRenderer>())
                go.SetActive(false);
        }

        for (int i = 0; i < visibleCount; i++)
        {
            int id = readBack[i].id;

            for (int k = 0; k < goes.Count; k++)
            {
                GameObject go = goes[k];
                int tmpId = go.GetInstanceID();
                if (id == tmpId)
                {
                    go.SetActive(true);//等于 1 不可见
                    break;
                }

            }
        }
    }
    private void OnDestroy()
    {
        if (posBuffer != null)
        {
            posBuffer.Release();
            posBuffer = null;
        }
        if (argsBuffer != null)
        {
            argsBuffer.Release();
            argsBuffer = null;
        }
        if (cullResult != null)
        {
            cullResult.Release();
            cullResult = null;
        }
    }
}
