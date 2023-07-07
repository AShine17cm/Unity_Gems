using System;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class VariantInfo
{
    public PoseVariant variant;
    public PoseVariant symetric;//对称的变体, 如果此位势 是一个旋转，缩放对称位置
}
//原型，未旋转，缩放的物件
public class PartProto : MonoBehaviour
{
    const float size = 1f;
    const float size_h = 0.5f;
    public PartType type;                   //唯一
    [Tooltip("X0,X1,Z0,Z1")]
    public Socket[] protoSockets;           //4个邻接位置
    //变体: 非旋转对称，非轴对称的变体
    public VariantInfo[] variantInfos;      //6个

    //计算所有的非对称变体
    public void GetPartVariants()
    {
        for (int i = 0; i < variantInfos.Length; i++)
        {
            PoseVariant pose = variantInfos[i].variant; //方位变体
            PoseVariant sym = variantInfos[i].symetric; //是否对称
            if (PoseVariant.Max != sym) continue;       //有对称?  可以直接 return

            //实例化出一个 非对称变体
            GameObject newGo = Instantiate<GameObject>(gameObject);
            PartProto proto = newGo.GetComponent<PartProto>();
            Transform tr = newGo.transform;
            tr.position = Vector3.zero;
            tr.localScale = Vector3.one;

            Socket[] protoSockets = proto.SetPose(pose);//原始插槽

            GameObject.Destroy(proto);
            Part part = new Part();
            List<int>[] sockets = new List<int>[4];             //映射到变体-id 的插槽
            List<float>[] probs = new List<float>[4];
            List<int>[] offsets = new List<int>[4];
            for (int k = 0; k < 4; k++)                         //4 个插槽
            {
                Socket side = protoSockets[k];          //边上的插槽
                int c = side.slots.Count;
                sockets[k] = new List<int>(128);
                probs[k] = new List<float>(128);
                offsets[k] = new List<int>(128);
                for(int x = 0; x < c; x++)
                {
                    Target target = side.slots[x];
                    PartType part_on_side = target.type;
                    for(int t = 0; t < target.poses.Count; t++)
                    {
                        PoseVariant pose_B = target.poses[t];
                        float prob = target.probability[t];
                        int offset = 0;
                        offset = target.offset[t];
                        PoseVariant pose_final = CombinePose(pose, pose_B);//最终的方位

                        //id 预先计算，源于<PartType,PoseVariant>
                        int id_on_side = GlobalVariants.GetId(part_on_side, pose_final);//插槽上的物体，随主物体旋转/缩放
                        sockets[k].Add(id_on_side);         //插槽上的PartType 直接映射到 variant-id
                        probs[k].Add(prob);
                        offsets[k].Add(offset);
                    }
                }
            }
            int id = GlobalVariants.GetId(type, pose);
            string name = gameObject.name + " _" + pose+ "_" + id;
            newGo.name = name;
            part.sockets = sockets;
            part.probabilites = probs;
            part.offsets = offsets;
            part.go = newGo;
            part.name = name;
            newGo.SetActive(false);
            GlobalVariants.AddPart(type, pose, part);//global-id 预先生成
        }
    }
    PoseVariant CombinePose(PoseVariant pose_a,PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_a)
        {
            case PoseVariant.Normal:
                final = pose_b;
                break;
            case PoseVariant.Rotate_90:
                final = Rotate90(pose_b);
                break;
            case PoseVariant.Rotate_180:
                final = Rotate180(pose_b);
                break;
            case PoseVariant.Rotate_270:
                final = Rotate270(pose_b);
                break;
            case PoseVariant.Flip_X:
                final = FlipX(pose_b);
                break;
            case PoseVariant.Flip_Z:
                final = FlipZ(pose_a);
                break;
        }
        return final;
    }
    PoseVariant FlipZ(PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_b)
        {
            case PoseVariant.Normal:
                final = PoseVariant.Flip_Z;
                break;
            case PoseVariant.Rotate_90:
                final = PoseVariant.Rotate_90_x1;
                break;
            case PoseVariant.Rotate_180:
                final = PoseVariant.Flip_X;
                break;
            case PoseVariant.Rotate_270:
                final = PoseVariant.Rotate_90_z1;
                break;
            case PoseVariant.Flip_X:
                final = PoseVariant.Rotate_180;
                break;
            case PoseVariant.Flip_Z:
                final = PoseVariant.Normal;
                break;
        }
        return final;
    }
    PoseVariant FlipX(PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_b)
        {
            case PoseVariant.Normal:
                final = PoseVariant.Flip_X;
                break;
            case PoseVariant.Rotate_90:
                final = PoseVariant.Rotate_90_z1;
                break;
            case PoseVariant.Rotate_180:
                final = PoseVariant.Flip_Z;
                break;
            case PoseVariant.Rotate_270:
                final = PoseVariant.Rotate_90_x1;
                break;
            case PoseVariant.Flip_X:
                final = PoseVariant.Normal;
                break;
            case PoseVariant.Flip_Z:
                final = PoseVariant.Rotate_180;
                break;
        }
        return final;
    }
    PoseVariant Rotate270(PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_b)
        {
            case PoseVariant.Normal:
                final = PoseVariant.Rotate_270;
                break;
            case PoseVariant.Rotate_90:
                final = PoseVariant.Normal;
                break;
            case PoseVariant.Rotate_180:
                final = PoseVariant.Rotate_90;
                break;
            case PoseVariant.Rotate_270:
                final = PoseVariant.Rotate_180;
                break;
            case PoseVariant.Flip_X:
                final = PoseVariant.Rotate_90_z1;
                break;
            case PoseVariant.Flip_Z:
                final = PoseVariant.Rotate_90_x1;
                break;
        }
        return final;
    }
    PoseVariant Rotate180(PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_b)
        {
            case PoseVariant.Normal:
                final = PoseVariant.Rotate_180;
                break;
            case PoseVariant.Rotate_90:
                final = PoseVariant.Rotate_270;
                break;
            case PoseVariant.Rotate_180:
                final = PoseVariant.Normal;
                break;
            case PoseVariant.Rotate_270:
                final = PoseVariant.Rotate_90;
                break;
            case PoseVariant.Flip_X:
                final = PoseVariant.Flip_Z;
                break;
            case PoseVariant.Flip_Z:
                final = PoseVariant.Flip_X;
                break;
        }
        return final;
    }
    PoseVariant Rotate90(PoseVariant pose_b)
    {
        PoseVariant final = pose_b;
        switch (pose_b)
        {
            case PoseVariant.Normal:
                final = PoseVariant.Rotate_90;
                break;
            case PoseVariant.Rotate_90:
                final = PoseVariant.Rotate_180;
                break;
            case PoseVariant.Rotate_180:
                final = PoseVariant.Rotate_270;
                break;
            case PoseVariant.Rotate_270:
                final = PoseVariant.Normal;
                break;
            case PoseVariant.Flip_X:
                final = PoseVariant.Rotate_90_x1;
                break;
            case PoseVariant.Flip_Z:
                final = PoseVariant.Rotate_90_z1;
                break;
        }
        return final;
    }
    //设定旋转，缩放, 得到6个新的 Part, 可能是6个
 public   Socket[] SetPose(PoseVariant pose)
    {
        Socket[] sockets = new Socket[4];

        Transform tr = transform;
        Vector3 euler = Vector3.zero;
        Vector3 scale = Vector3.one;

        switch (pose)
        {
            case PoseVariant.Normal:
                euler = Vector3.zero;
                break;
            case PoseVariant.Rotate_90:
                euler = new Vector3(0, 90, 0);
                break;
            case PoseVariant.Rotate_180:
                euler = new Vector3(0, 180, 0);
                break;
            case PoseVariant.Rotate_270:
                euler = new Vector3(0, 270, 0);
                break;
            case PoseVariant.Flip_X:
                scale = new Vector3(-1, 1, 1);
                break;
            case PoseVariant.Flip_Z:
                scale = new Vector3(1, 1, -1);
                break;
        }
        tr.localScale = scale;
        tr.eulerAngles = euler;
        sockets[0] = GetSocket(PartDir.X0);
        sockets[1] = GetSocket(PartDir.X1);
        sockets[2] = GetSocket(PartDir.Z0);
        sockets[3] = GetSocket(PartDir.Z1);
        return sockets;
    }
    //返回此 方位的插槽
    Socket GetSocket(PartDir dir)
    {
        Vector3[] skPoses = new Vector3[4];
        //世界坐标
        for (int i = 0; i < 4; i++)
        {
            Vector3 posWS = protoSockets[i].transform.position;
            skPoses[i] = posWS;
        }
        Vector3 center3 = transform.position;
        Vector2 center2 = new Vector2(center3.x, center3.z);
        Vector2 borderPos = center2;
        switch (dir)
        {
            case PartDir.X0:
                borderPos += new Vector2(-size_h, 0);
                break;
            case PartDir.X1:
                borderPos += new Vector2(size_h, 0);
                break;
            case PartDir.Z0:
                borderPos -= new Vector2(0, -size_h);
                break;
            case PartDir.Z1:
                borderPos += new Vector2(0, size_h);
                break;
        }
        int idx = GetMin(borderPos, skPoses);
        return protoSockets[idx];
    }
    //最近socket
    int GetMin(Vector2 test, Vector3[] skPoses)
    {
        int idx = -1;
        float min = float.MaxValue;
        float tmp;
        for (int i = 0; i < 4; i++)
        {
            tmp = Vector2.Distance(test, skPoses[i]);
            if (tmp < min)
            {
                min = tmp;
                idx = i;
            }
        }
        return idx;
    }
}
