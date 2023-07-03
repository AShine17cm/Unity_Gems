using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Threading;

namespace ThreadCulling
{
    public class CullData
    {
        public void Clear()
        {

        }
        public void StartCull()
        {

        }

    }
    public class Dx_ThreadCullHelper : MonoBehaviour
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
                if (t != null)
                {
                    if (t.IsAlive)
                    {
                        t.Join();
                    }
                    //应用结果
                    //ApplyResult();
                    data.Clear();
                    t = null;
                }
 
                t = new Thread(data.StartCull);
                t.Start();

            }
        }



    }
}