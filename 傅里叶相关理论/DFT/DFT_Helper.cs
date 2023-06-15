using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;
public class DFT_Helper
{
    /* Direct fourier transform */
    //m �� Ƶ�׼���, 512��ͼ,m=9
    
    void DFT(int dir, int m, double[] x1, double[] y1)
    {
        float PI = Mathf.PI;

        long i, k;
        double arg;
        double cosarg, sinarg;

        double[] x2 = new double[m];
        double[] y2 = new double[m];

        //dir �ķ�����ʼ, ��Բ������ M�ηָ�
        for (i = 0; i < m; i++)
        {
            x2[i] = 0;
            y2[i] = 0;
            //M �ηָ��һ������
            arg = -dir * 2.0 * PI * (double)i / (double)m;
            //����������� M �� ����Ҷ�任
            for (k = 0; k < m; k++)
            {
                cosarg = Math.Cos(k * arg);
                sinarg = Math.Sin(k * arg);
                //һ����ת (������) 
                x2[i] += (x1[k] * cosarg - y1[k] * sinarg);
                y2[i] += (x1[k] * sinarg + y1[k] * cosarg);
            }
        }

        //������ ������ȥ
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
            //һ�� ����/stage
            for(i=0;i<m;i++)
            {
                x1[i] = x2[i];
                y1[i] = y2[i];
            }
        }

    }
}
