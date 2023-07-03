using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using JobCuller;

public class Occluder : MonoBehaviour
{
    public Vector2 extend;      //half size
    public GameObject refGo;
    public float vault = 50;
    public OccluderData GetJobData()
    {
        Transform tr = transform;
        OccluderData data = new OccluderData();
        //类型，名称
        data.id = gameObject.GetInstanceID();
        //空间信息
        data.pos = tr.position;
        data.right = tr.right;
        data.up = tr.up;
        data.fwd = tr.forward;
        data.wld2Local = tr.worldToLocalMatrix;
        //大小
        data.rect = new Rect(Vector2.zero, extend * 2.0f);
        return data;
    }
    private void OnDrawGizmos()
    {
        Transform tr = transform;
        Vector3 pos = tr.position;
        Vector3 p1 = pos - tr.up * extend.x - tr.right * extend.y;
        Vector3 p2 = pos + tr.up * extend.x - tr.right * extend.y;
        Vector3 p3 = pos + tr.up * extend.x + tr.right * extend.y;
        Vector3 p4 = pos - tr.up * extend.x + tr.right * extend.y;

        Gizmos.color = Color.black;
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p4);
        Gizmos.DrawLine(p4, p1);

        if (refGo != null)
        {
            Vector3 posRef = refGo.transform.position;
            MeshRenderer mr = refGo.GetComponentInChildren<MeshRenderer>();
            float sqrRadius = mr.bounds.extents.sqrMagnitude;
            float radius = Mathf.Sqrt(sqrRadius);

            Matrix4x4 world2View = Camera.main.worldToCameraMatrix; //z 是负值
            Matrix4x4 world2Clip = Camera.main.projectionMatrix * Camera.main.worldToCameraMatrix;
            int scrWidth = Screen.width;
            int scrHeight = Screen.height;

            float dist = world2View.MultiplyPoint(pos).z;
            float dist2Camera = world2View.MultiplyPoint(posRef).z;
            radius = radius * dist / dist2Camera;

            Rect rect = new Rect(Vector2.zero, this.extend * 2.0f);
            Rect rect2 = rect;
            rect2.size = rect.size - Vector2.one * radius * 2f;   //收缩 rect

            Vector2 extend = rect2.size / 2;
            //四个角位置
            p1 = pos - tr.up * extend.x - tr.right * extend.y;
            p2 = pos + tr.up * extend.x - tr.right * extend.y;
            p3 = pos + tr.up * extend.x + tr.right * extend.y;
            p4 = pos - tr.up * extend.x + tr.right * extend.y;
            //先画线
            Gizmos.color = Color.red;
            Gizmos.DrawLine(p1, p2);
            Gizmos.DrawLine(p2, p3);
            Gizmos.DrawLine(p3, p4);
            Gizmos.DrawLine(p4, p1);

            //转换到 view-space
            p1 = world2Clip.MultiplyPoint(p1);
            p2 = world2Clip.MultiplyPoint(p2);
            p3 = world2Clip.MultiplyPoint(p3);
            p4 = world2Clip.MultiplyPoint(p4);
            Vector2 s1, s2, s3, s4;
            Vector3 scrPos = world2Clip.MultiplyPoint(posRef);
            s1 = new Vector2(p1.x * scrWidth, p1.y * scrHeight);
            s2 = new Vector2(p2.x * scrWidth, p2.y * scrHeight);
            s3 = new Vector2(p3.x * scrWidth, p3.y * scrHeight);
            s4 = new Vector2(p4.x * scrWidth, p4.y * scrHeight);
            Vector2 sp = new Vector2(scrPos.x * scrWidth, scrPos.y * scrHeight);
            float area = CullingJob.Area(s1, s2, s3) + CullingJob.Area(s3, s4, s1);
            float area2 = CullingJob.Area(s1, s2, sp) + CullingJob.Area(s2, s3, sp) + CullingJob.Area(s3, s4, sp) + CullingJob.Area(s4, s1, sp);
            
            Color tintVisible = Color.green;
            if (area2 < area + vault)//不可见
            {
                tintVisible = Color.red;
            }
            Gizmos.color = tintVisible;
            Gizmos.DrawLine(pos, posRef);
        }
    }
}
