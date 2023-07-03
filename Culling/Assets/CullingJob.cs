using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Unity.Collections;
using Unity.Jobs;

//Allocator.Temp        1 ֡
//Allocator.TempJob     4 ֡
//Allocator.Persistent  app����������,ʵ�ʵ��� malloc
namespace JobCuller
{
    public struct OccludeeData      //���ڵ���
    {
        public int id;              //instance id
        public Vector3 posWS;
        public float sqrRadius;

        public float radius;        //job �м���
        public float distToCamera;
        public int state;
    }

    public struct OccluderData      //�ڵ��� ����ǽ
    {
        public int id;
        public Vector3 pos;
        public Vector3 up, right, fwd;     //��ͶӰ�� ����ƽ����
        public Rect rect;           //���� ʱ��ʹ�ñ��ڵ����radius ������һ��
        public Matrix4x4 wld2Local;
        public float distToCamera;
    }
    public struct OcResult
    {
        public int id;
        public int state;
    }
    public struct CullingJob : IJob
    {
        public Matrix4x4 world2View;
        public Matrix4x4 world2Clip;
        public int scrWidth, scrHeight;
        public float vault;
        public Vector3 camPos;
        public NativeArray<OccludeeData> occludees;
        public NativeArray<OccluderData> occluders;

        public NativeArray<OcResult> result;
        public void Execute()
        {
            int counter = 0;
            //��һ�� Ԥ���� �뾶��������ľ���
            for (int i = 0; i < occludees.Length; i++)
            {
                OccludeeData cee = occludees[i];
                cee.radius = Mathf.Sqrt(cee.sqrRadius);
                float dist = world2View.MultiplyPoint(cee.posWS).z;
                cee.distToCamera = dist;
                occludees[i] = cee;
            }
            for (int i = 0; i < occluders.Length; i++)
            {
                OccluderData occluder = occluders[i];
                Vector3 posVS = world2View.MultiplyPoint(occluder.pos);
                occluder.distToCamera = posVS.z;
                occluders[i] = occluder;
            }
            for (int i = 0; i < occluders.Length; i++)//ÿһ���ڵ���
            {
                OccluderData occluder = occluders[i];
                float distOC = occluder.distToCamera;
                Rect rect = occluder.rect;
                Rect rect2 = rect;
                Vector3 pos = occluder.pos;

                for (int k = 0; k < occludees.Length; k++)//ÿһ�����ڵ���
                {
                    OccludeeData cee = occludees[k];
                    if (cee.state == 1) continue;                                   //�Ѿ����ڵ� ?
                    float radius = cee.radius;
                    float distToCamera = cee.distToCamera;
                    if (-distToCamera < (-distOC)) continue;                        //С��OC ������, Z �Ǹ�ֵ
                    radius = radius * distOC / distToCamera;                        //���� raidus

                    rect2.size = rect.size - Vector2.one * radius * 2f;   //���� rect
                    if (rect2.size.x <= 0 || rect2.size.y <= 0) continue;
                    Vector2 extend = rect2.size / 2;
                    //�ĸ���λ��
                    Vector3 p1 = pos - occluder.up * extend.x - occluder.right * extend.y;
                    Vector3 p2 = pos + occluder.up * extend.x - occluder.right * extend.y;
                    Vector3 p3 = pos + occluder.up * extend.x + occluder.right * extend.y;
                    Vector3 p4 = pos - occluder.up * extend.x + occluder.right * extend.y;
                    Vector2 s1, s2, s3, s4;
                    //ת���� view-space
                    p1 = world2Clip.MultiplyPoint(p1);
                    p2 = world2Clip.MultiplyPoint(p2);
                    p3 = world2Clip.MultiplyPoint(p3);
                    p4 = world2Clip.MultiplyPoint(p4);
                    Vector3 scrPos = world2Clip.MultiplyPoint(cee.posWS);
                    s1 = new Vector2(p1.x * scrWidth, p1.y * scrHeight);
                    s2 = new Vector2(p2.x * scrWidth, p2.y * scrHeight);
                    s3 = new Vector2(p3.x * scrWidth, p3.y * scrHeight);
                    s4 = new Vector2(p4.x * scrWidth, p4.y * scrHeight);
                    //��Ļ�ռ� ������������� �������ż��
                    Vector2 sp = new Vector2(scrPos.x * scrWidth, scrPos.y * scrHeight);
                    float area = Area(s1, s2, s3) + Area(s3, s4, s1);
                    float area2 = Area(s1, s2, sp) + Area(s2, s3, sp) + Area(s3, s4, sp) + Area(s4, s1, sp);
                    if (area2 < area + vault)//��Ļ ���ؿռ�
                    {
                        cee.state = 1;  //���ɼ�
                        occludees[k] = cee;
                        counter += 1;
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
        //���׹�ʽ
        public static float Area(Vector2 a, Vector2 b, Vector2 c)
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