using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Threading;

namespace ThreadCulling
{
    public class CullData
    {
        public List<OccludeeData> occludeeDatas = new List<OccludeeData>(1024);
        public List<OccluderData> occluderDatas = new List<OccluderData>(1024);
        public Vector3 camPos;
        public Vector3 camFwd;
        public int counter;
        public void Clear()
        {
            occludeeDatas.Clear();
            occluderDatas.Clear();
            counter = 0;
        }
        public void StartCull()
        {
            for(int i=0;i<occluderDatas.Count;i++)//每一个遮挡物
            {
                OccluderData occluder = occluderDatas[i];
                Rect rect = occluder.rect;
                Rect rect2 = rect;
                Vector3 vec = occluder.pos - camPos;
                vec.Normalize();
                float dotCam = Vector3.Dot(vec, occluder.fwd);  //相对于 camera的朝向
                for(int k=0;k<occludeeDatas.Count;k++)//每一个被遮挡物
                {
                    OccludeeData cee = occludeeDatas[k];
                    if (cee.state == 1) continue;                                   //已经被遮挡 ?
                    rect2.size = rect.size +new Vector2( cee.radius,cee.radius);    //扩张 rect

                    /////////////
                    ///
                    /// 需要投影到屏幕上，计算 交点的奇偶数
                    Vector3 local3 = occluder.wld2Local.MultiplyPoint(cee.posWS);   //转换到 local  
                    Vector2 local2 = new Vector2(local3.x, local3.y);
                    if(local3.z*dotCam>0)//与 相机的朝向一致
                    {
                        if(rect.Contains(local2))
                        {
                            cee.state = 1;  //不可见
                            occludeeDatas[k] = cee;
                            counter += 1;
                        }

                    }

                }
            }
            Debug.Log("剔除数量遮挡物:" + counter);
        }

    }
}