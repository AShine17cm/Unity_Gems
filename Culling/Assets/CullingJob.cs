using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Unity.Collections;
using Unity.Jobs;

//Allocator.Temp        1 帧
//Allocator.TempJob     4 帧
//Allocator.Persistent  app的生命周期,实际调用 malloc
namespace JobCuller
{
    public struct OccludeeData      //被遮挡物
    {
        public int id;              //instance id
        public Vector3 posWS;
        public float sqrRadius;
        public float radius;        //job 中计算
        public int state;
    }

    public struct OccluderData      //遮挡物 空气墙
    {
        public int id;
        public int kind;
        public Vector3 pos;
        public Vector3 up, right, fwd;     //再投影到 矩形平面上
        public Rect rect;           //测试 时，使用被遮挡物的radius 先扩张一下
        public Matrix4x4 wld2Local;
    }
    public struct OcResult
    {
        public int id;
        public int state;
    }
    public struct CullingJob : IJob
    {
        public Matrix4x4 world2Screen;
        public Vector3 camPos, camFwd;
        public NativeArray<OccludeeData> occludees;
        public NativeArray<OccluderData> occluders;

        public NativeArray<OcResult> result;
        public void Execute()
        {
            int counter = 0;
            for (int i = 0; i < occludees.Length; i++)//计算半径
            {
                OccludeeData cee = occludees[i];
                cee.radius = Mathf.Sqrt(cee.sqrRadius);
                occludees[i] = cee;
            }
            for (int i = 0; i < occluders.Length; i++)//每一个遮挡物
            {
                OccluderData occluder = occluders[i];
                Rect rect = occluder.rect;
                Rect rect2 = rect;
                Vector3 vec = occluder.pos - camPos;
                vec.Normalize();
                float dotCam = Vector3.Dot(vec, occluder.fwd);  //相对于 camera的朝向
                Vector3 pos = occluder.pos;

                for (int k = 0; k < occludees.Length; k++)//每一个被遮挡物
                {
                    OccludeeData cee = occludees[k];
                    if (cee.state == 1) continue;                                   //已经被遮挡 ?
                    float radius = cee.radius;

                    rect2.size = rect.size - Vector2.one * radius * 2f;   //收缩 rect
                    if (rect2.size.x <= 0 || rect2.size.y <= 0) continue;
                    Vector2 extend = rect2.size;
                    //四个角位置
                    Vector3 p1 = pos - occluder.up * extend.x - occluder.right * extend.y;
                    Vector3 p2 = pos + occluder.up * extend.x - occluder.right * extend.y;
                    Vector3 p3 = pos + occluder.up * extend.x + occluder.right * extend.y;
                    Vector3 p4 = pos - occluder.up * extend.x + occluder.right * extend.y;
                    Vector2 s1, s2, s3, s4;
                    //转换到 view-space
                    p1 = world2Screen.MultiplyPoint(p1);
                    p2 = world2Screen.MultiplyPoint(p2);
                    p3 = world2Screen.MultiplyPoint(p3);
                    p4 = world2Screen.MultiplyPoint(p4);
                    Vector3 scrPos = world2Screen.MultiplyPoint(cee.posWS);
                    s1 = new Vector2(p1.x, p1.y);
                    s2 = new Vector2(p2.x, p2.y);
                    s3 = new Vector2(p3.x, p3.y);
                    s4 = new Vector2(p4.x, p4.y);
                    Vector2 sp = new Vector2(scrPos.x, scrPos.y);
                    float area = Area(s1, s2, s3) + Area(s3, s4, s1);
                    float area2 = Area(s1, s2, sp) + Area(s2, s3, sp) + Area(s3, s4, sp) + Area(s4, s1, sp);
                    if (area2 < area + 0.1f)
                    {
                        // 需要投影到屏幕上，计算 交点的奇偶数
                        Vector3 local3 = occluder.wld2Local.MultiplyPoint(cee.posWS);   //转换到 local  
                        if (local3.z * dotCam > 0)//与 相机的朝向一致
                        {
                            cee.state = 1;  //不可见
                            occludees[k] = cee;
                            counter += 1;
                        }
                    }
                }
            }
            //
            for (int i = 0; i < occludees.Length; i++)
            {
                OccludeeData cee = occludees[i];
                result[i] = new OcResult { id = cee.id, state = cee.state };
            }
        }
        //海伦公式
        float Area(Vector2 a, Vector2 b, Vector2 c)
        {
            float distA = Vector2.Distance(a, b);
            float distB = Vector2.Distance(b, c);
            float distC = Vector2.Distance(c, a);

            float p = (distA + distB + distC) / 2f;
            float area = Mathf.Sqrt(p * (p - distA) * (p - distB) * (p - distC));
            return area;
        }
    }
}