using UnityEngine;

public class FastFourierTransform
{
    //至少64,类同 缓存线/Cache-Line 的概念
    const int WORK_GROUPS_X = 8;
    const int WORK_GROUPS_Y = 8;

    readonly int size;              //256
    readonly ComputeShader fftShader;
    public readonly RenderTexture precomputedData;  //8*256  蝶形网络那堆数据

    public FastFourierTransform(int size, ComputeShader fftShader)  //256
    {
        this.size = size;
        this.fftShader = fftShader;

        //2D 傅里叶变换，横竖两趟
        K_Horizon_FFT = fftShader.FindKernel("HorizontalStepFFT");
        K_Horizon_IFFT = fftShader.FindKernel("HorizontalStepInverseFFT");
        K_Vertical_FFT = fftShader.FindKernel("VerticalStepFFT");
        K_Vertical_IFFT = fftShader.FindKernel("VerticalStepInverseFFT");

        K_Scale = fftShader.FindKernel("Scale");
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
        fftShader.Dispatch(K_Precompute, logSize, size / 2 / WORK_GROUPS_Y, 1);//<8,16,1>
        return rt;
    }
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
            fftShader.Dispatch(K_Horizon_FFT, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
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
            fftShader.Dispatch(K_Vertical_FFT, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
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

    public void IFFT2D(RenderTexture input, RenderTexture buffer, bool outputToInput = false, bool scale = true, bool permute = false)
    {
        int logSize = (int)Mathf.Log(size, 2);
        bool pingPong = false;
        //2D 逆变换 横的
        fftShader.SetTexture(K_Horizon_IFFT, ID_Precompute_Data, precomputedData);
        fftShader.SetTexture(K_Horizon_IFFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Horizon_IFFT, ID_Buffer1, buffer);
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Horizon_IFFT, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
        }
        //2D 逆变换 竖的
        fftShader.SetTexture(K_Vertical_IFFT, ID_Precompute_Data, precomputedData);
        fftShader.SetTexture(K_Vertical_IFFT, ID_Buffer0, input);
        fftShader.SetTexture(K_Vertical_IFFT, ID_Buffer1, buffer);
        for (int i = 0; i < logSize; i++)
        {
            pingPong = !pingPong;
            fftShader.SetInt(ID_Step, i);
            fftShader.SetBool(ID_PingPong, pingPong);
            fftShader.Dispatch(K_Vertical_IFFT, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
        }

        if (pingPong && outputToInput)
        {
            Graphics.Blit(buffer, input);
        }

        if (!pingPong && !outputToInput)
        {
            Graphics.Blit(input, buffer);
        }
        //
        if (permute)
        {
            fftShader.SetInt(ID_Size, size);
            fftShader.SetTexture(K_Permute, ID_Buffer0, outputToInput ? input : buffer);
            fftShader.Dispatch(K_Permute, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
        }
        
        if (scale)
        {
            fftShader.SetInt(ID_Size, size);
            fftShader.SetTexture(K_Scale, ID_Buffer0, outputToInput ? input : buffer);
            fftShader.Dispatch(K_Scale, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
        }
    }

    // Kernel
    readonly int K_Precompute=6;
    readonly int K_Horizon_FFT;
    readonly int K_Vertical_FFT;
    readonly int K_Horizon_IFFT;
    readonly int K_Vertical_IFFT;
    readonly int K_Scale;
    readonly int K_Permute;

    readonly int ID_Precompute_Buffer = Shader.PropertyToID("PrecomputeBuffer");
    readonly int ID_Precompute_Data = Shader.PropertyToID("PrecomputedData");
    readonly int ID_Buffer0 = Shader.PropertyToID("Buffer0");
    readonly int ID_Buffer1 = Shader.PropertyToID("Buffer1");
    readonly int ID_Size = Shader.PropertyToID("Size");
    readonly int ID_Step = Shader.PropertyToID("Step");
    readonly int ID_PingPong = Shader.PropertyToID("PingPong");
}
