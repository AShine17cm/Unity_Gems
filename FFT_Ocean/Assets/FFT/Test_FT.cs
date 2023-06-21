using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Complex = DFT_Helper.COMPLEX;
/*
 用 cpu 实现，测试 傅里叶变换
 */
public class Test_FT : MonoBehaviour
{
    public Texture2D source;
    Texture2D fourierTex;
    Texture2D resultTex;

    public bool doTest = false;
    public bool useFFT = true;

    public RawImage srcImg;
    public RawImage fourierImg;
    public RawImage resultImg;
    public RectTransform trOverlay;
    //public bool applyOverlay = true;
    public float brightCorrect = 5f;
    [Range(0, 0.9f)]
    public float filter_High = 0;    
    [Range(0.6f, 1.001f)]
    public float filter_Low = 1.001f;
    int dir = 1;                    //傅里叶变换的方向
    Complex[][] fourierRaw_R;         //原始的 频域数据
    Complex[][] fourierRaw_G;
    Complex[][] fourierRaw_B;
    Complex[][] fourierFiltered_R;    //滤波之后的数据
    Complex[][] fourierFiltered_G;
    Complex[][] fourierFiltered_B;
    float last_filter_High;
    float last_filter_Low;
    void Start()
    {
        srcImg.texture = source;
        last_filter_High = filter_High;
        last_filter_Low = filter_Low;
        int w = source.width;
        int h = source.height;
        fourierTex = new Texture2D(w, h, TextureFormat.RGBA32, false);
        fourierTex.filterMode = FilterMode.Point;
        resultTex = new Texture2D(w, h, TextureFormat.RGBA32, false);
        resultTex.filterMode = FilterMode.Bilinear;
    }

    void Update()
    {
        if (Input.GetMouseButtonUp(0))
        {
            Vector3 pos = Input.mousePosition;
            Vector2 localPos;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(srcImg.GetComponent<RectTransform>(), pos, null, out localPos);
            trOverlay.anchoredPosition = localPos;
            doTest = true;
        }
        if (fourierRaw_R != null)
        {
            if (Mathf.Abs(last_filter_High - filter_High) > float.Epsilon)
            {
                last_filter_High = filter_High;
                Display(source.width, Vector2Int.zero);
                fourierTex.Apply();
                resultTex.Apply();
            }
            if (Mathf.Abs(last_filter_Low - filter_Low) > float.Epsilon)
            {
                last_filter_Low = filter_Low;
                Display(source.width, Vector2Int.zero);
                fourierTex.Apply();
                resultTex.Apply();
            }
        }
        if (doTest)
        {
            doTest = false;

            int size = source.width;
            Vector2Int offset = Vector2Int.zero;
            fourierFiltered_R = new Complex[size][];
            fourierFiltered_G = new Complex[size][];
            fourierFiltered_B = new Complex[size][];
            fourierRaw_R = new Complex[size][];
            fourierRaw_G = new Complex[size][];
            fourierRaw_B = new Complex[size][];
            DoQuad(size, offset);

            fourierTex.Apply();
            resultTex.Apply();
            fourierImg.texture = fourierTex;
            resultImg.texture = resultTex;
        }
    }
    void DoQuad(int ofSize, Vector2Int offset)
    {
        fourierRaw_R = new Complex[ofSize][];
        for (int r = 0; r < ofSize; r++)
        {
            fourierRaw_R[r] = new Complex[ofSize];
            fourierRaw_G[r] = new Complex[ofSize];
            fourierRaw_B[r] = new Complex[ofSize];
            fourierFiltered_R[r] = new Complex[ofSize];
            fourierFiltered_G[r] = new Complex[ofSize];
            fourierFiltered_B[r] = new Complex[ofSize];
            for (int c = 0; c < ofSize; c++)
            {
                Vector2Int uv = offset + new Vector2Int(r, c);
                Color color = source.GetPixel(uv.x, uv.y);
                Complex complex = new Complex();
                complex.real = color.r;
                fourierRaw_R[r][c] = complex;  //写到对应位置
                complex.real = color.g;
                fourierRaw_G[r][c] = complex;  //写到对应位置
                complex.real = color.b;
                fourierRaw_B[r][c] = complex;  //写到对应位置
            }
        }
        //叠加 overlay 信号
        //if (applyOverlay)
        //{
        //    Vector2 size = trOverlay.sizeDelta;
        //    Vector2 pos = trOverlay.anchoredPosition;
        //    Vector2 srcSize = srcImg.GetComponent<RectTransform>().sizeDelta;
        //    float atx0 = (srcSize.x / 2 + pos.x - size.x / 2) / srcSize.x;
        //    float atx1 = (srcSize.x / 2 + pos.x + size.x / 2) / srcSize.x;
        //    float aty0 = (srcSize.y / 2 + pos.y - size.y / 2) / srcSize.y;
        //    float aty1 = (srcSize.y / 2 + pos.y + size.y / 2) / srcSize.y;
        //    int x0 = Mathf.Clamp((int)(atx0 * ofSize), 0, ofSize);
        //    int x1 = Mathf.Clamp((int)(atx1 * ofSize), 0, ofSize);
        //    int y0 = Mathf.Clamp((int)(aty0 * ofSize), 0, ofSize);
        //    int y1 = Mathf.Clamp((int)(aty1 * ofSize), 0, ofSize);
        //    Color overlayColor = trOverlay.GetComponent<Image>().color;
        //    for (int r = x0; r < x1; r++)
        //    {
        //        for (int c = y0; c < y1; c++)
        //        {
        //            Complex cp = fourierRaw_R[r][c];
        //            Vector2Int uv = offset + new Vector2Int(r, c);
        //            cp.real += overlayColor.r;
        //            cp.real = Mathf.Clamp(cp.real, 0, 1);
        //            fourierRaw_R[r][c] = cp;  //写到对应位置
        //        }
        //    }
        //}
        DFT_Helper.FFT2D(fourierRaw_R, ofSize, ofSize, dir, useFFT);      //转换到 频率
        DFT_Helper.FFT2D(fourierRaw_G, ofSize, ofSize, dir, useFFT);      //转换到 频率
        DFT_Helper.FFT2D(fourierRaw_B, ofSize, ofSize, dir, useFFT);      //转换到 频率
        Display(ofSize, offset);
    }
    void Display(int ofSize, Vector2Int offset)
    {
        //拷贝一份 频率数据
        for (int k = 0; k < ofSize; k++)
        {
            for (int L = 0; L < ofSize; L++)
            {
                fourierFiltered_R[k][L] = fourierRaw_R[k][L];
                fourierFiltered_G[k][L] = fourierRaw_G[k][L];
                fourierFiltered_B[k][L] = fourierRaw_B[k][L];
            }
        }
        //滤波
        Vector2Int center = new Vector2Int(1, 1) * ofSize / 2;
        float high = ofSize / 2;
        high =filter_High* high * high;
        for (int m = 0; m < ofSize; m++)
        {
            for (int n = 0; n < ofSize; n++)
            {
                if ((new Vector2Int(m, n) - center).sqrMagnitude < high)
                {
                    fourierFiltered_R[m][n] = new Complex();
                    fourierFiltered_G[m][n] = new Complex();
                    fourierFiltered_B[m][n] = new Complex();
                }
            }
        }
        float low = ofSize / 2;
        low = filter_Low * low * low * 2;//对角线
        for (int m = 0; m < ofSize; m++)
        {
            for (int n = 0; n < ofSize; n++)
            {
                if ((new Vector2Int(m, n) - center).sqrMagnitude > low)
                {
                    fourierFiltered_R[m][n] = new Complex();
                    fourierFiltered_G[m][n] = new Complex();
                    fourierFiltered_B[m][n] = new Complex();
                }
            }
        }

        //滤波之后的 频域数据
        for (int r = 0; r < ofSize; r++)
        {
            Complex[] row_R = fourierFiltered_R[r];
            Complex[] row_G = fourierFiltered_G[r];
            Complex[] row_B = fourierFiltered_B[r];
            for (int c = 0; c < ofSize; c++)
            {
                Vector2Int uv = offset + new Vector2Int(r, c);
                float real_R = row_R[c].real;
                float imag_R = row_R[c].imag;
                float val_R;
                val_R = Mathf.Sqrt(real_R * real_R + imag_R * imag_R);
                val_R = Mathf.Pow(val_R, 1 / brightCorrect);

                float real_G = row_G[c].real;
                float imag_G = row_G[c].imag;
                float val_G;
                val_G = Mathf.Sqrt(real_G * real_G + imag_G * imag_G);
                val_G = Mathf.Pow(val_G, 1 / brightCorrect);

                float real_B = row_B[c].real;
                float imag_B = row_B[c].imag;
                float val_B;
                val_B = Mathf.Sqrt(real_B * real_B + imag_B * imag_B);
                val_B = Mathf.Pow(val_B, 1 / brightCorrect);


                Color color = new Color(val_R, val_G, val_B, 1);
                fourierTex.SetPixel(uv.x, uv.y, color);
            }
        }

        DFT_Helper.FFT2D(fourierFiltered_R, ofSize, ofSize, -dir, useFFT); //将信号 从频域变换回来
        DFT_Helper.FFT2D(fourierFiltered_G, ofSize, ofSize, -dir, useFFT); //将信号 从频域变换回来
        DFT_Helper.FFT2D(fourierFiltered_B, ofSize, ofSize, -dir, useFFT); //将信号 从频域变换回来
        //变回 颜色空间的数据
        for (int r = 0; r < ofSize; r++)
        {
            Complex[] row_R = fourierFiltered_R[r];
            Complex[] row_G = fourierFiltered_G[r];
            Complex[] row_B = fourierFiltered_B[r];
            for (int c = 0; c < ofSize; c++)
            {
                Vector2Int uv = offset + new Vector2Int(r, c);
                float real_R = row_R[c].real;
                float imag_R = row_R[c].imag;
                float val_R;
                val_R = Mathf.Sqrt(real_R * real_R + imag_R * imag_R);

                float real_G = row_G[c].real;
                float imag_G = row_G[c].imag;
                float val_G;
                val_G = Mathf.Sqrt(real_G * real_G + imag_G * imag_G);

                float real_B = row_B[c].real;
                float imag_B = row_B[c].imag;
                float val_B;
                val_B = Mathf.Sqrt(real_B * real_B + imag_B * imag_B);

                Color color = new Color(val_R, val_G, val_B, 1);
                resultTex.SetPixel(uv.x, uv.y, color);
            }
        }
    }
}
