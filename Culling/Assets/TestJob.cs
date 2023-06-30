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
    public LayerMask occluderMask;      //�ڵ���  ����ǽ
    public LayerMask occludeeMask;      //���ڵ���  ��Ͱ����ľ
    public float dist = 10f;         //���ڴ˾��� �����޳�
    float sqrDist;

    List<GameObject> goes = new List<GameObject>(1024);
    public List<OccludeeData> occludeeDatas = new List<OccludeeData>(1024);
    public List<OccluderData> occluderDatas = new List<OccluderData>(1024);

    JobHandle handle;
    NativeArray<OccluderData> occluders;    //�ڵ���
    NativeArray<OccludeeData> occludees;    //���ڵ���
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
        //if (Time.frameCount % 4 == 0)//ÿ 10 ֡��һ��
        //{
        //    ApplyResult();
        //    Collect(cam);
        //}
        Collect(cam);

        //���䣬����������
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

    public void Collect(Camera cam) //�ռ�����
    {
        occluderDatas.Clear();
        occludeeDatas.Clear();
        goes.Clear();

        Transform camTr = cam.transform;
        camPos = camTr.position;
        camFwd = camTr.forward;

        float angDegree = cam.fieldOfView;
        float ang = angDegree * Mathf.Deg2Rad / 2;

        //���Ե���Ұ��Χ
        float cos = Mathf.Cos(ang);
        float cosOccluder = Mathf.Cos(ang + Mathf.PI / 6);  //�ڵ���� �ݲ�Ƕ� ���Դ�һЩ

        Scene scene = SceneManager.GetActiveScene();
        scene.GetRootGameObjects(goes);

        for (int i = 0; i < goes.Count; i++)
        {
            GameObject go = goes[i];
            // ���ڵ���
            if ((go.layer & (~occludeeMask)) != 0)
            {
                MeshRenderer mr = go.GetComponentInChildren<MeshRenderer>();
                if (mr)
                {
                    Transform tr = go.transform;
                    Vector3 posWS = tr.position;
                    Vector3 vec = posWS - camPos;
                    float sqr = vec.sqrMagnitude;
                    if (sqr > sqrDist)//�Ծ��� Camera �㹻Զ �����޳�����
                    {
                        float dot = Vector3.Dot(vec / Mathf.Sqrt(sqr), camFwd);
                        if (dot > cos)//���Եİ�׵���С����
                        {
                            OccludeeData occ = new OccludeeData();
                            occ.id = go.GetInstanceID();
                            occ.sqrRadius = mr.bounds.extents.sqrMagnitude;
                            //occ.radius = mr.bounds.extents.magnitude; //�����ݿ����߳��ϼ���
                            occ.posWS = tr.position;
                            occ.state = -1;                 //״̬��ȷ��
                            occludeeDatas.Add(occ);
                        }
                        //Debug.Log("dot:" + dot + "  name:" + go.name);
                    }
                }
            }
            //�ڵ���
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
        //Debug.Log("���ڵ��� ����:" + occludeeDatas.Count + "   �ڵ��� ����:" + occluderDatas.Count);
    }
    void ApplyResult()
    {
        Transform camTr = cam.transform;
        camPos = camTr.position;
        camFwd = camTr.forward;

        //���Ե���Ұ��Χ

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
                    go.SetActive(state != 1);//���� 1 ���ɼ�
                    break;
                }

            }
        }


    }
}
