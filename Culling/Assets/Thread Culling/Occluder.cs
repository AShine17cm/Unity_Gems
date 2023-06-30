using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Occluder : MonoBehaviour
{
    public int kind = 0;        //对应算法
    public float radius;
    public Vector2 extend;      //half size
    public Color tint = Color.red;

    public ThreadCulling.OccluderData GetData()
    {
        Transform tr = transform;
        ThreadCulling.OccluderData data = new ThreadCulling.OccluderData();
        //类型，名称
        data.id = gameObject.GetInstanceID();
        data.kind = 0;
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
    public JobCuller.OccluderData GetJobData()
    {
        Transform tr = transform;
        JobCuller.OccluderData data = new JobCuller.OccluderData();
        //类型，名称
        data.id = gameObject.GetInstanceID();
        data.kind = 0;
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

        Gizmos.color = tint;
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p4);
        Gizmos.DrawLine(p4, p1);
    }
}
