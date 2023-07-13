using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Probabi
{
    public List<int> ids = new List<int>(64);
    public List<float> probabi = new List<float>(64);
    public List<int> offset = new List<int>(64);
    public List<float> Left_P = new List<float>(64);
    public List<float> Top_P = new List<float>(64);
    public void Clear()
    {
        ids.Clear();
        probabi.Clear();
        offset.Clear();

        Left_P.Clear();
        Top_P.Clear();
    }
}
//原型的一个状态(旋转，缩放)
public class Part
{
    //      z-1
    //  x-0  +  x-1
    //      z-0
    public List<int>[] sockets;// x0,x1,z0,z1
    public List<float>[] probabilites;
    public List<int>[] offsets;

    public GameObject go;
    public string name;

    //根据上下，获得可用 id
    public static void Cross(Probabi probs, int id_left, int id_top)
    {
        probs.Clear();

        Part part_Left = null;
        Part part_top = null;
        if (id_left >= 0)
        {
            part_Left = GlobalVariants.variants[id_left];
        }
        if (id_top >= 0)
        {
            part_top = GlobalVariants.variants[id_top];
        }

        int k = -1;
        if (id_left < 0)
        {
            if (id_top >= 0)
            {
                k = 2;//z0;
                probs.ids.AddRange(part_top.sockets[k]);
                probs.probabi.AddRange(part_top.probabilites[k]);
                probs.offset.AddRange(part_top.offsets[k]);

                probs.Left_P.AddRange(part_top.probabilites[k]);
                probs.Top_P.AddRange(part_top.probabilites[k]);
            }
        }
        if (id_top < 0)
        {
            if (id_left >= 0)
            {
                k = 1;//x1
                probs.ids.AddRange(part_Left.sockets[k]);
                probs.probabi.AddRange(part_Left.probabilites[k]);
                probs.offset.AddRange(part_Left.offsets[k]);

                probs.Left_P.AddRange(part_Left.probabilites[k]);
                probs.Top_P.AddRange(part_Left.probabilites[k]);
            }
        }
        if (id_left >= 0 && id_top >= 0)
        {
            List<int> lefts = part_Left.sockets[1];//x1
            List<int> height_L = part_Left.offsets[1];
            List<float> p_left = part_Left.probabilites[1];

            List<int> tops = part_top.sockets[2];//z0
            List<int> height_T = part_top.offsets[2];
            List<float> p_top = part_top.probabilites[2];
            for (int L = 0; L < lefts.Count; L++)
            {
                for (int T = 0; T < tops.Count; T++)
                {
                    if (lefts[L] == tops[T])
                    {
                        probs.ids.Add(lefts[L]);
                        probs.Left_P.Add(p_left[L]);
                        probs.Top_P.Add(p_top[T]);
                        probs.probabi.Add(p_left[L] + p_top[T]);

                        int h_L = height_L[L];
                        int h_T = height_T[T];
                        if (h_L == h_T)
                        {
                            probs.offset.Add(height_L[L]);
                        }
                        else
                        {
                            probs.offset.Add(0);
                            int id_X = lefts[L];
                            string name_x = GlobalVariants.variants[id_X].name;
                            Debug.Log("<Color=red> 高度 不匹配 </Color> Left:" + part_Left.name + "   Top:" + part_top.name+"  G:"+name_x);
                        }

                        break;
                    }
                }//for T
            }//for L
        }//
    }//Cross
}
