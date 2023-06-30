using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ThreadCulling
{
    public struct OccludeeData      //被遮挡物
    {
        public int id;              //instance id
        public string name;
        public Vector3 posWS;
        public Bounds bd;
        public float radius;

        public int state;
    }

    public struct OccluderData      //遮挡物 空气墙
    {
        public int id;
        public int kind;
        public Matrix4x4 wld2Local; //先转换 local space
        public Vector3 pos;     
        public Vector3 up, right,fwd;     //再投影到 矩形平面上
        public Rect rect;           //测试 时，使用被遮挡物的radius 先扩张一下
        public float radius;        //简化一下
    }
    //public struct CullResult
    //{
    //    public int id;
    //    public string name;
    //    public int state;
    //}
}