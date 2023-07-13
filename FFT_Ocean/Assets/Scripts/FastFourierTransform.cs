using UnityEngine;

public class FastFourierTransform
{
    //至少64,类同 缓存线/Cache-Line 的概念
    const int WORK_GROUPS = 8;

    readonly int size,group;                        //256,32
    readonly ComputeShader fftShader;
    public readonly RenderTexture precomputedData;  //8*256  蝶形网络那堆数据 IFFT

    public FastFourierTransform(int size, ComputeShader fftShader)  //256
    {
        this.size = size;
        this.fftShader = fftShader;
        group = size / WORK_GROUPS;
        //2D 傅里叶变换，横竖两趟
        K_Horizon_FFT = fftShader.FindKernel("HorizontalStepFFT");
        K_Horizon_IFFT = fftShader.FindKernel("HorizontalStepInverseFFT");
        K_Vertical_FFT = fftShader.FindKernel("VerticalStepFFT");
        K_Vertical_IFFT = fftShader.FindKernel("VerticalStepInverseFFT");

        K_Permute = fftShader.FindKernel("Permute");
        K_Precompute = fftShader.FindKernel("PrecomputeTwiddleFactorsAndInputIndices");

        precomputedData = PrecomputeTwiddleFactorsAndInputIndices();
    }

    public static RenderTexture CreateRenderTexture(int size, RenderTextureFormat format = RenderTextureFormat.RGFloat, bool useMips = false)
    {
        RenderTexture rt = new RenderTexture(size, size, 0, format, RenderTextureReadWrite.Linear);
        rt.useMipMap = useMips;
        rt.autoGenerateMips = false;
        rt.anisoLevel = 6;
        rt.filterMode = FilterMode.Trilinear;
        rt.wrapMode = TextureWrapMode.Repeat;
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }


    RenderTexture PrecomputeTwiddleFactorsAndInputIndices()
    {
        int logSize = (int)Mathf.Log(size, 2);
        //<8,256>
        RenderTexture rt = new RenderTexture(logSize, size, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        rt.filterMode = FilterMode.Point;
        rt.wrapMode = TextureWrapMode.Repeat;
        rt.enableRandomWrite = true;
        rt.Create();

        fftShader.SetInt(ID_Size, size);
        fftShader.SetTexture(K_Precompute, ID_Precompute_Buffer, rt);
        fftShader.Dispatch(K_Precompute, logSize, group / 2 , 1);//<8,16,1>
        return rt;
    }

    //逆傅里叶变换 从频域转换到 空间  
    public void IFFT2D(RenderTexture input, RenderTexture buffer)
    {
        int logSize = (int)Mathf.Log(size, 2);//8
        bool pingPong = false;
        //2D 逆变换 横的
        fftShader.SetTexture(K_Horizon_IFFT, ID_Precompute_Data, precomputedData);  //蝶形交换网络
        fftShader.SetTexture(K_Horizon_IFFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Horizon_IFFT, ID_Buffer1, buffer);//输出
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);                           //0,1,2,3,4,5,6,7
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Horizon_IFFT, group, group, 1);
        }
        //2D 逆变换 竖的
        fftShader.SetTexture(K_Vertical_IFFT, ID_Precompute_Data, precomputedData);
        fftShader.SetTexture(K_Vertical_IFFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Vertical_IFFT, ID_Buffer1, buffer);//输出
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Vertical_IFFT, group, group, 1);
        }
        if (true)//permute
        {
            fftShader.SetInt(ID_Size, size);
            fftShader.SetTexture(K_Permute, ID_Buffer0, input);
            fftShader.Dispatch(K_Permute, group, group, 1);
        }
    }

    // Kernel
    readonly int K_Precompute;
    readonly int K_Horizon_IFFT;
    readonly int K_Vertical_IFFT;
    readonly int K_Permute;

    readonly int K_Horizon_FFT;
    readonly int K_Vertical_FFT;

    readonly int ID_Precompute_Buffer = Shader.PropertyToID("PrecomputeBuffer");
    readonly int ID_Precompute_Data = Shader.PropertyToID("PrecomputedData");
    readonly int ID_Buffer0 = Shader.PropertyToID("Buffer0");
    readonly int ID_Buffer1 = Shader.PropertyToID("Buffer1");
    readonly int ID_Size = Shader.PropertyToID("Size");
    readonly int ID_Step = Shader.PropertyToID("Step");
    readonly int ID_PingPong = Shader.PropertyToID("PingPong");

    public void FFT2D(RenderTexture input, RenderTexture buffer, bool outputToInput = false)
    {
        int logSize = (int)Mathf.Log(size, 2);
        bool pingPong = false;

        //2D  先 horizon
        fftShader.SetTexture(K_Horizon_FFT, ID_Precompute_Data, precomputedData);
        fftShader.SetTexture(K_Horizon_FFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Horizon_FFT, ID_Buffer1, buffer);
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Horizon_FFT, group, group, 1);//<32,32,1>
        }
        //2D  再 vertical
        fftShader.SetTexture(K_Vertical_FFT, ID_Precompute_Data, precomputedData);
        fftShader.SetTexture(K_Vertical_FFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Vertical_FFT, ID_Buffer1, buffer);
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Vertical_FFT, group, group, 1);
        }

        if (pingPong && outputToInput)
        {
            Graphics.Blit(buffer, input);
        }

        if (!pingPong && !outputToInput)
        {
            Graphics.Blit(input, buffer);
        }
    }
}
