using UnityEngine;
using System.Collections;

namespace PhillipsOcean
{
	
    public class FourierCPU
    {
        int size;
        int stages;     //size 以2为底数的指数
		float[] butterflyLookupTable = null;

        public FourierCPU(int size)
        {
            if (!Mathf.IsPowerOfTwo(size))
            {
                size = Mathf.NextPowerOfTwo(size);
            }

            this.size = size; //must be pow2 num
            stages =(int) Mathf.Log(size, 2.0f);
            ComputeButterflyLookupTable();
        }
        //蝶形交换Lut
        //列数是 stage  行数是fourier信号
        //x,y 是 信号的index    z,w 是系数
        void ComputeButterflyLookupTable()
        {
            butterflyLookupTable = new float[size * stages * 4];

            for (int i = 0; i < stages; i++)
            {
                int nBlocks = (int)Mathf.Pow(2, stages - 1 - i);
                int nHInputs = (int)Mathf.Pow(2, i);

                for (int j = 0; j < nBlocks; j++)
                {
                    for (int k = 0; k < nHInputs; k++)
                    {
                        int i1, i2, j1, j2;
                        if (i == 0)
                        {
                            i1 = j * nHInputs * 2 + k;
                            i2 = j * nHInputs * 2 + nHInputs + k;
                            j1 = BitReverse(i1);
                            j2 = BitReverse(i2);
                        }
                        else
                        {
                            i1 = j * nHInputs * 2 + k;
                            i2 = j * nHInputs * 2 + nHInputs + k;
                            j1 = i1;
                            j2 = i2;
                        }

                        float wr = Mathf.Cos(2.0f * Mathf.PI * (float)(k * nBlocks) / size);
                        float wi = Mathf.Sin(2.0f * Mathf.PI * (float)(k * nBlocks) / size);

                        int offset1 = 4 * (i1 + i * size);
                        butterflyLookupTable[offset1 + 0] = j1;
                        butterflyLookupTable[offset1 + 1] = j2;
                        butterflyLookupTable[offset1 + 2] = wr;
                        butterflyLookupTable[offset1 + 3] = wi;

                        int offset2 = 4 * (i2 + i * size);
                        butterflyLookupTable[offset2 + 0] = j1;
                        butterflyLookupTable[offset2 + 1] = j2;
                        butterflyLookupTable[offset2 + 2] = -wr;
                        butterflyLookupTable[offset2 + 3] = -wi;
                    }
                }
            }
        }

        //Performs two FFTs on two complex numbers packed in a vector4
        Vector4 FFT(Vector2 w, Vector4 input1, Vector4 input2)
        {
            input1.x += w.x * input2.x - w.y * input2.y;
            input1.y += w.y * input2.x + w.x * input2.y;
            input1.z += w.x * input2.z - w.y * input2.w;
            input1.w += w.y * input2.z + w.x * input2.w;

            return input1;
        }

        //Performs one FFT on a complex number
        Vector2 FFT(Vector2 w, Vector2 input1, Vector2 input2)
        {
            input1.x += w.x * input2.x - w.y * input2.y;
            input1.y += w.y * input2.x + w.x * input2.y;

            return input1;
        }

        public int PeformFFT(int startIdx, Vector2[,] data0, Vector4[,] data1, Vector4[,] data2)
        {

            int x; int y; int i;
            int idx = 0; int idx1; int bftIdx;
            int X; int Y;
            Vector2 w;

            int j = startIdx;

            for (i = 0; i < stages; i++, j++)
            {
                idx = j % 2;
                idx1 = (j + 1) % 2;

                for (x = 0; x < size; x++)
                {
                    for (y = 0; y < size; y++)
                    {
                        bftIdx = 4 * (x + i * size);

                        X = (int)butterflyLookupTable[bftIdx + 0];
                        Y = (int)butterflyLookupTable[bftIdx + 1];
                        w.x = butterflyLookupTable[bftIdx + 2];
                        w.y = butterflyLookupTable[bftIdx + 3];

                        data0[idx, x + y * size] = FFT(w, data0[idx1, X + y * size], data0[idx1, Y + y * size]);
                        data1[idx, x + y * size] = FFT(w, data1[idx1, X + y * size], data1[idx1, Y + y * size]);
                        data2[idx, x + y * size] = FFT(w, data2[idx1, X + y * size], data2[idx1, Y + y * size]);
                    }
                }
            }

            for (i = 0; i < stages; i++, j++)
            {
                idx = j % 2;
                idx1 = (j + 1) % 2;

                for (x = 0; x < size; x++)
                {
                    for (y = 0; y < size; y++)
                    {
                        bftIdx = 4 * (y + i * size);

                        X = (int)butterflyLookupTable[bftIdx + 0];
                        Y = (int)butterflyLookupTable[bftIdx + 1];
                        w.x = butterflyLookupTable[bftIdx + 2];
                        w.y = butterflyLookupTable[bftIdx + 3];

                        data0[idx, x + y * size] = FFT(w, data0[idx1, x + X * size], data0[idx1, x + Y * size]);
                        data1[idx, x + y * size] = FFT(w, data1[idx1, x + X * size], data1[idx1, x + Y * size]);
                        data2[idx, x + y * size] = FFT(w, data2[idx1, x + X * size], data2[idx1, x + Y * size]);
                    }
                }
            }

            return idx;
        }

        //蝶形交换的 信号排列顺序	是	输入顺的(1,2,3....)的  字节翻转
        int BitReverse(int i)
        {
            int j = i;
            int Sum = 0;
            int W = 1;
            int M = size / 2;
            while (M != 0)
            {
                j = ((i & M) > M - 1) ? 1 : 0;
                Sum += j * W;
                W *= 2;
                M /= 2;
            }
            return Sum;
        }
    }

}

















