using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;
public class DFT_Helper
{
    public struct COMPLEX
    {
        public float real;
        public float imag;
    }
    /*-------------------------------------------------------------------------
   Perform a 2D FFT inplace given a complex 2D array
   The direction dir, 1 for forward, -1 for reverse
   The size of the array (nx,ny)
   Return false if there are memory problems or
      the dimensions are not powers of 2
*/
    public static int FFT2D(COMPLEX[][] c, int nx, int ny, int dir,bool isFFT)
    {
        
        int i, j;
        int m=0, twopm=0;
        float[] real = new float[nx];
        float[] imag = new float[nx];

        /* Transform the rows */
        if (Powerof2(nx, ref m, ref twopm)==0 || twopm != nx)
            return 0;
        for (j = 0; j < ny; j++)//逐行
        {
            for (i = 0; i < nx; i++)        //提取到临时的 行数组
            {
                real[i] = c[i][j].real;
                imag[i] = c[i][j].imag;
            }
            if(isFFT)
            {
                FFT(dir, m, real, imag);        //变换 一行
            }
            else
            {
                DFT(dir, twopm, real, imag);
            }
            for (i = 0; i < nx; i++)        //写出结果 到原位置
            {
                c[i][j].real = real[i];
                c[i][j].imag = imag[i];
            }
        }
        //return 1;
        /* Transform the columns */
        real = new float[ny];
        imag = new float[ny];
        if (Powerof2(ny, ref m, ref twopm)==0 || twopm != ny)
            return 0;
        for (i = 0; i < nx; i++)//逐列
        {
            for (j = 0; j < ny; j++)
            {
                real[j] = c[i][j].real;
                imag[j] = c[i][j].imag;
            }
            if(isFFT)
            {
                FFT(dir, m, real, imag); //写出结果到列
            }
            else
            {
                DFT(dir, twopm, real, imag);
            }
            for (j = 0; j < ny; j++)
            {
                c[i][j].real = real[j];
                c[i][j].imag = imag[j];
            }
        }

        return 1;
    }
    //离散傅里叶变换
    // x1实部， y1虚部

    public static bool DFT(int dir, int m, float[] x1, float[] y1)
    {
        int i, k;
        float arg;
        float cosarg, sinarg;
        float[] x2 = new float[m];
        float[] y2 = new float[m];


        for (i = 0; i < m; i++)
        {
            x2[i] = 0;
            y2[i] = 0;
            arg = -dir * 2.0f * 3.141592654f * i / m;
            for (k = 0; k < m; k++)
            {
                cosarg = Mathf.Cos(k * arg);
                sinarg = Mathf.Sin(k * arg);
                x2[i] += (x1[k] * cosarg - y1[k] * sinarg);
                y2[i] += (x1[k] * sinarg + y1[k] * cosarg);
            }
        }

        /* Copy the data back */
        if (dir == 1)
        {
            for (i = 0; i < m; i++)
            {
                x1[i] = x2[i] / m;
                y1[i] = y2[i] / m;
            }
        }
        else
        {
            for (i = 0; i < m; i++)
            {
                x1[i] = x2[i];
                y1[i] = y2[i];
            }
        }

        return true;
    }

    /*
   This computes an in-place complex-to-complex FFT 
   x and y are the real and imaginary arrays of 2^m points.
   dir =  1 gives forward transform
   dir = -1 gives reverse transform 
*/
    public static bool FFT(int dir, int m, float[] x, float[] y)
    {
        int n, i, i1, j, k, i2, l, l1, l2;
        float c1, c2, tx, ty, t1, t2, u1, u2, z;

        /* Calculate the number of points */
        n = 1;
        for (i = 0; i < m; i++)
            n *= 2;

        /* Do the bit reversal */
        i2 = n >> 1;
        j = 0;
        for (i = 0; i < n - 1; i++)
        {
            if (i < j)
            {
                tx = x[i];
                ty = y[i];
                x[i] = x[j];
                y[i] = y[j];
                x[j] = tx;
                y[j] = ty;
            }
            k = i2;
            while (k <= j)
            {
                j -= k;
                k >>= 1;
            }
            j += k;
        }

        /* Compute the FFT */
        c1 = -1.0f;
        c2 = 0.0f;
        l2 = 1;
        for (l = 0; l < m; l++)
        {
            l1 = l2;
            l2 <<= 1;
            u1 = 1.0f;
            u2 = 0.0f;
            for (j = 0; j < l1; j++)
            {
                for (i = j; i < n; i += l2)
                {
                    i1 = i + l1;
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
            c2 = Mathf.Sqrt((1.0f - c1) / 2.0f);
            if (dir == 1)
                c2 = -c2;
            c1 = Mathf.Sqrt((1.0f + c1) / 2.0f);
        }

        /* Scaling for forward transform */
        if (dir == 1)
        {
            for (i = 0; i < n; i++)
            {
                x[i] /= n;
                y[i] /= n;
            }
        }

        return true;
    }

    /*-------------------------------------------------------------------------
   Calculate the closest but lower power of two of a number
   twopm = 2**m <= n
   Return TRUE if 2**m == n
    */
    static int Powerof2(int n, ref int m, ref int twopm)
    {
        if (n <= 1)
        {
            m = 0;
            twopm = 1;
            return 0;
        }

        m = 1;
        twopm = 2;
        do
        {
            m++;
            twopm *= 2;
        } while (2 * twopm <= n);

        if (twopm != n)
            return 0;
        else
            return 1;
    }
}
