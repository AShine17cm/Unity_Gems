using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;

//http://paulbourke.net/miscellaneous/dft/

//2D  傅里叶
//1.    对每一行做 FT, 用结果替换每一行
//2.    对每一列做 FT, 用结果替换每一列
public class FFT_Helper
{
    //复数结构
    struct complex
    {
        public double real;
        public double imag;
    }
    //nx==ny 宽高相等,dir = 1 傅里叶变换
    void FFT_2D(complex[][] c,int nx,int ny,int dir)
    {
        int i, j;
        int m;
        double[] real = new double[nx];
        double[] imag = new double[nx];

        m =(int) Math.Log(nx,2);        //幂次
  
        //先做 行的 FT
        for(j=0;j<ny;j++)
        {
            //分离<实部，虚部> 到 一维数组
            for(i=0;i<nx; i++)
            {
                real[i] = c[i][j].real;// i/row 变化
                imag[i] = c[i][j].imag;
            }
            FFT(dir, m, real, imag);
            //写入 变换结果
            for(i=0;i<nx;i++)
            {
                c[i][j].real = real[i];
                c[i][j].imag = imag[i];
            }
        }

        //做 列的 FT
        for(i=0;i<nx;i++)
        {
            for(j=0;j<ny;j++)
            {
                real[j] = c[i][j].real;// j/col 变化
                imag[j] = c[i][j].imag;
            }
            FFT(dir, m, real, imag);
            //写入 变换结果
            for(j=0;j<ny;j++)
            {
                c[i][j].real = real[j];
                c[i][j].imag = imag[j];
            }
        }
    }
    //x 实部， y虚部, 512 的图,m=9, dir=1 是 Forward Transform
    /*
      Formula: forward
                  N-1
                  ---
              1   \          - j k 2 pi n / N
      X(n) = ---   >   x(k) e                    = forward transform
              N   /                                n=0..N-1
                  ---
                  k=0

      Formula: reverse
                  N-1
                  ---
                  \          j k 2 pi n / N
      X(n) =       >   x(k) e                    = forward transform
                  /                                n=0..N-1
                  ---
                  k=0
     */
    void FFT(int dir,long m,double[] x,double[] y)
    {
        long n, i, i1, j, k, i2;
        long L, L1, L2;
        double c1, c2, tx, ty, t1, t2, u1, u2, z;

        //点数:512
        n =(int) Math.Pow(2, m);
        //位反转  bit reversal
        i2 = n >> 1;    // 256
        j = 0;
        //1.  j移动到 n>>1, 交换 前后两部分的内容
        //蝶形交换 ?
        for(i=0;i<n-1;i++)
        {
            if(i<j)//交换 i与j的值
            {
                tx = x[i];
                ty = y[i];
                x[i] = x[j];
                y[i] = y[j];
                x[j] = tx;
                y[j] = ty;
            }

            k = i2;
            while(k<=j)
            {
                j -= k; //j>=0
                k =k>>1;// k 减半
            }
            j += k;//移动到中间 : 第一次 j移动 n>>1
        }
        //计算 FFT
        c1 = -1.0;
        c2 = 0.0;
        L2 = 1;
        for(L=0;L<m;L++)
        {
            L1 = L2;
            L2 =L2<< 1;
            u1 = 1.0;
            u2 = 0.0;
            for(j=0;j<L1;j++)
            {
                for(i=j;i<n;i+=L2)
                {
                    i1 = i + L1;
                    t1 = u1 * x[i1] - u2 * y[i1];
                    t2 = u1 * y[i1] + u2 * x[i1];
                    x[i1] = x[i] - t1;
                    y[i1] = y[i] - t2;
                    x[i] += t1;
                    y[i] += t2;
                }
                z = u1 * c1 - u2 * c2;
                u2 = u1 * c2 + u2 * c1;
                u1 = z;
            }
            c2 = Math.Sqrt((1.0 - c1) / 2.0);
            if(dir==1)//傅里叶变换
            {
                c2 = -c2;
            }
            c1 = Math.Sqrt((1.0 + c1) / 2.0);
        }

        if(dir==1)//傅里叶变换
        {
            for(i=0;i<n;i++)
            {
                x[i] /= n;
                y[i] /= n;
            }
        }
    }
}
