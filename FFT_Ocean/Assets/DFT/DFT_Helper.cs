using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;
public class DFT_Helper
{
    /* Direct fourier transform */
    //m 是 频谱集合, 512的图,m=9
    
    void DFT(int dir, int m, double[] x1, double[] y1)
    {
        float PI = Mathf.PI;

        long i, k;
        double arg;
        double cosarg, sinarg;

        double[] x2 = new double[m];
        double[] y2 = new double[m];

        //dir 的反方向开始, 在圆周上做 M次分割
        for (i = 0; i < m; i++)
        {
            x2[i] = 0;
            y2[i] = 0;
            //M 次分割的一个方向
            arg = -dir * 2.0 * PI * (double)i / (double)m;
            //这个方向在做 M 次 傅里叶变换
            for (k = 0; k < m; k++)
            {
                cosarg = Math.Cos(k * arg);
                sinarg = Math.Sin(k * arg);
                //一个旋转 (本质上) 
                x2[i] += (x1[k] * cosarg - y1[k] * sinarg);
                y2[i] += (x1[k] * sinarg + y1[k] * cosarg);
            }
        }

        //将数据 拷贝回去
        if (dir == 1)
        {
            for (i = 0; i < m; i++)
            {
                x1[i] = x2[i] / (double)m;
                y1[i] = y2[i] / (double)m;
            }
        }
        else
        {
            //一次 迭代/stage
            for(i=0;i<m;i++)
            {
                x1[i] = x2[i];
                y1[i] = y2[i];
            }
        }

    }
}
