using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

using Unity.Collections;
using Unity.Jobs;

using JobCuller;
public class TestJob : MonoBehaviour
{
    public Camera cam;
    public LayerMask occluderMask;      //遮挡物  空气墙
    public LayerMask occludeeMask;      //被遮挡物  油桶，树木
    public float dist = 10f;         //大于此距离 才做剔除
    float sqrDist;

    List<GameObject> goes = new List<GameObject>(1024);
    public List<OccludeeData> occludeeDatas = new List<OccludeeData>(1024);
    public List<OccluderData> occluderDatas = new List<OccluderData>(1024);

    JobHandle handle;
    NativeArray<OccluderData> occluders;    //遮挡物
    NativeArray<OccludeeData> occludees;    //被遮挡物
    NativeArray<OcResult> ocResults;

    Vector3 camPos;
    Vector3 camFwd;
    void Start()
    {
        sqrDist = dist * dist;
    }

    // Update is called once per frame
    void Update()
    {
        //if (Time.frameCount % 4 == 0)//每 10 帧做一次
        //{
        //    ApplyResult();
        //    Collect(cam);
        //}
        Collect(cam);

        //分配，并拷贝数据
        occluders = new NativeArray<OccluderData>(occluderDatas.Count, Allocator.TempJob);
        occludees = new NativeArray<OccludeeData>(occludeeDatas.Count, Allocator.TempJob);
        ocResults = new NativeArray<OcResult>(occludeeDatas.Count, Allocator.TempJob);
        for(int i=0;i<occluderDatas.Count;i++)
        {
            occluders[i] = occluderDatas[i];
        }
        for(int i = 0; i < occludeeDatas.Count; i++)
        {
            occludees[i] = occludeeDatas[i];
        }

        CullingJob jobData = new CullingJob
        {
            //world2View = cam.worldToCameraMatrix,
            world2Screen = cam.projectionMatrix * cam.worldToCameraMatrix,
            camPos=camPos,
            camFwd=camFwd,
            occluders = occluders,
            occludees = occludees,
            result = ocResults
        };

        handle = jobData.Schedule();
    }

    private void LateUpdate()
    {
        handle.Complete();

        ApplyResult();

        occluders.Dispose();
        occludees.Dispose();
        ocResults.Dispose();
    }

    public void Collect(Camera cam) //收集数据
    {
        occluderDatas.Clear();
        occludeeDatas.Clear();
        goes.Clear();

        Transform camTr = cam.transform;
        camPos = camTr.position;
        camFwd = camTr.forward;

        float angDegree = cam.fieldOfView;
        float ang = angDegree * Mathf.Deg2Rad / 2;

        //粗略的视野范围
        float cos = Mathf.Cos(ang);
        float cosOccluder = Mathf.Cos(ang + Mathf.PI / 6);  //遮挡物的 容差角度 可以大一些

        Scene scene = SceneManager.GetActiveScene();
        scene.GetRootGameObjects(goes);

        for (int i = 0; i < goes.Count; i++)
        {
            GameObject go = goes[i];
            // 被遮挡物
            if ((go.layer & (~occludeeMask)) != 0)
            {
                MeshRenderer mr = go.GetComponentInChildren<MeshRenderer>();
                if (mr)
                {
                    Transform tr = go.transform;
                    Vector3 posWS = tr.position;
                    Vector3 vec = posWS - camPos;
                    float sqr = vec.sqrMagnitude;
                    if (sqr > sqrDist)//对距离 Camera 足够远 才做剔除运算
                    {
                        float dot = Vector3.Dot(vec / Mathf.Sqrt(sqr), camFwd);
                        if (dot > cos)//粗略的半椎体大小测试
                        {
                            OccludeeData occ = new OccludeeData();
                            occ.id = go.GetInstanceID();
                            occ.sqrRadius = mr.bounds.extents.sqrMagnitude;
                            //occ.radius = mr.bounds.extents.magnitude; //此数据可子线程上计算
                            occ.posWS = tr.position;
                            occ.state = -1;                 //状态不确定
                            occludeeDatas.Add(occ);
                        }
                        //Debug.Log("dot:" + dot + "  name:" + go.name);
                    }
                }
            }
            //遮挡物
            //if ((go.layer & (~occluderMask)) != 0)
            {
               Occluder occluder = go.GetComponent<Occluder>();
                if (occluder)
                {
                    Transform tr = go.transform;
                    Vector3 posWS = tr.position;
                    Vector3 vec = posWS - camPos;
                    if (Vector3.Dot(vec.normalized, camFwd) > cosOccluder)
                    {
                        OccluderData cer = occluder.GetJobData();
                        occluderDatas.Add(cer);
                    }
                }
            }
        }
        //Debug.Log("被遮挡物 数量:" + occludeeDatas.Count + "   遮挡物 数量:" + occluderDatas.Count);
    }
    void ApplyResult()
    {
        Transform camTr = cam.transform;
        camPos = camTr.position;
        camFwd = camTr.forward;

        //粗略的视野范围

        Scene scene = SceneManager.GetActiveScene();
        goes.Clear();
        scene.GetRootGameObjects(goes);

        for (int i = 0; i < ocResults.Length; i++)
        {
            int id = ocResults[i].id;
            int state = ocResults[i].state;

            for (int k = 0; k < goes.Count; k++)
            {
                GameObject go = goes[k];

                if (id == go.GetInstanceID())
                {
                    go.SetActive(state != 1);//等于 1 不可见
                    break;
                }

            }
        }


    }
}
