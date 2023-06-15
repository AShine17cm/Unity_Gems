using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;

//http://paulbourke.net/miscellaneous/dft/

//2D  ����Ҷ
//1.    ��ÿһ���� FT, �ý���滻ÿһ��
//2.    ��ÿһ���� FT, �ý���滻ÿһ��
public class FFT_Helper
{
    //�����ṹ
    struct complex
    {
        public double real;
        public double imag;
    }
    //nx==ny ������,dir = 1 ����Ҷ�任
    void FFT_2D(complex[][] c,int nx,int ny,int dir)
    {
        int i, j;
        int m;
        double[] real = new double[nx];
        double[] imag = new double[nx];

        m =(int) Math.Log(nx,2);        //�ݴ�
  
        //���� �е� FT
        for(j=0;j<ny;j++)
        {
            //����<ʵ�����鲿> �� һά����
            for(i=0;i<nx; i++)
            {
                real[i] = c[i][j].real;// i/row �仯
                imag[i] = c[i][j].imag;
            }
            FFT(dir, m, real, imag);
            //д�� �任���
            for(i=0;i<nx;i++)
            {
                c[i][j].real = real[i];
                c[i][j].imag = imag[i];
            }
        }

        //�� �е� FT
        for(i=0;i<nx;i++)
        {
            for(j=0;j<ny;j++)
            {
                real[j] = c[i][j].real;// j/col �仯
                imag[j] = c[i][j].imag;
            }
            FFT(dir, m, real, imag);
            //д�� �任���
            for(j=0;j<ny;j++)
            {
                c[i][j].real = real[j];
                c[i][j].imag = imag[j];
            }
        }
    }
    //x ʵ���� y�鲿, 512 ��ͼ,m=9, dir=1 �� Forward Transform
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

        //����:512
        n =(int) Math.Pow(2, m);
        //λ��ת  bit reversal
        i2 = n >> 1;    // 256
        j = 0;
        //1.  j�ƶ��� n>>1, ���� ǰ�������ֵ�����
        //���ν��� ?
        for(i=0;i<n-1;i++)
        {
            if(i<j)//���� i��j��ֵ
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
                k =k>>1;// k ����
            }
            j += k;//�ƶ����м� : ��һ�� j�ƶ� n>>1
        }
        //���� FFT
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
            if(dir==1)//����Ҷ�任
            {
                c2 = -c2;
            }
            c1 = Math.Sqrt((1.0 + c1) / 2.0);
        }

        if(dir==1)//����Ҷ�任
        {
            for(i=0;i<n;i++)
            {
                x[i] /= n;
                y[i] /= n;
            }
        }
    }
}
