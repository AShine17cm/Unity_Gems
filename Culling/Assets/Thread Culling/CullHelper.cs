using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Threading;

namespace ThreadCulling
{
    public class CullHelper : MonoBehaviour
    {
        public Camera cam;

        public Vector3 camPos;
        public Vector3 camFwd;
        public LayerMask occluderMask;      //遮挡物  空气墙
        public LayerMask occludeeMask;      //被遮挡物  油桶，树木
        public float dist = 10f;         //大于此距离 才做剔除
        float sqrDist;

        List<GameObject> goes = new List<GameObject>(1024);

        CullData data = new CullData();

        Thread t;
        private void Start()
        {
            sqrDist = dist * dist;

        }
        private void Update()
        {
            if (Time.frameCount % 10 == 0)//每 10 帧做一次
            {
                //ThreadState state = t.ThreadState;
                if (t != null)
                {
                    if (t.IsAlive)
                    {
                        t.Join();
                    }

                    //应用结果
                    ApplyResult();
                    data.Clear();
                    t = null;
                }
                Collect(cam);
                t = new Thread(data.StartCull);
                t.Start();

            }
        }

        public void Collect(Camera cam) //收集数据
        {
            data.Clear();

            Transform camTr = cam.transform;
            camPos = camTr.position;
            camFwd = camTr.forward;
            data.camPos = camPos;
            data.camFwd = camFwd;
            float angDegree = cam.fieldOfView;
            float ang = angDegree * Mathf.Deg2Rad / 2;

            //粗略的视野范围
            float cos = Mathf.Cos(ang);
            float cosOccluder = Mathf.Cos(ang + Mathf.PI / 6);  //遮挡物的 容差角度 可以大一些

            Scene scene = SceneManager.GetActiveScene();
            goes.Clear();
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
                                occ.bd = mr.bounds;
                                occ.id = go.GetInstanceID();
                                occ.name = go.name;
                                occ.posWS = tr.position;
                                occ.radius = mr.bounds.extents.magnitude; //此数据可子线程上计算
                                occ.state = -1;                 //状态不确定
                                data.occludeeDatas.Add(occ);
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
                            OccluderData cer = occluder.GetData();
                            data.occluderDatas.Add(cer);
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

            for (int i = 0; i < data.occludeeDatas.Count; i++)
            {
                int id = data.occludeeDatas[i].id;
                int state = data.occludeeDatas[i].state;

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
        private void OnDrawGizmos()
        {
            Vector3 pos = cam.transform.position;

            Gizmos.color = Color.white;
            Gizmos.DrawWireSphere(pos, dist);
        }
    }
}