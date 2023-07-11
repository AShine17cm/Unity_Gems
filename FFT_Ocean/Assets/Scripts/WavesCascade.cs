using System;
using UnityEngine;

public class WavesCascade
{
    const int WORK_GROUPS = 8;
    public RenderTexture Displacement => displacement;
    public RenderTexture Derivatives => derivatives;
    public RenderTexture Turbulence => turbulence;
    readonly int size,group;
    readonly ComputeShader init_Spectrum;       //初始化函数
    readonly ComputeShader timed_Spectrum;
    readonly ComputeShader tex_Merge;
    readonly FastFourierTransform fft;          //外部构造
    readonly Texture2D gaussianNoise;

    readonly ComputeBuffer paramsBuffer;
    public readonly RenderTexture initialSpectrum; 
    public readonly RenderTexture precomputedData;
    //最终渲染输出 用
    readonly RenderTexture displacement;    //顶点位移
    readonly RenderTexture derivatives;     //法线
    readonly RenderTexture turbulence;      //扰动
    
    public readonly RenderTexture buffer;
    public readonly RenderTexture DxDz;            //顶点位移
    public readonly RenderTexture DyDxz;           //顶点位移,扰动-泡沫
    public readonly RenderTexture DyxDyz;          //法线
    public readonly RenderTexture DxxDzz;          //法线，扰动-泡沫


    float lambda;

    public WavesCascade(int size,
                        ComputeShader init_Spectrum,
                        ComputeShader timed_Spectrum,
                        ComputeShader tex_Merge,
                        FastFourierTransform fft,
                        Texture2D gaussianNoise)
    {
        this.size = size;
        this.init_Spectrum = init_Spectrum;
        this.timed_Spectrum = timed_Spectrum;
        this.tex_Merge = tex_Merge;
        this.fft = fft;
        this.gaussianNoise = gaussianNoise;
        group = size / WORK_GROUPS;
        //核函数
        K_Initial_Spectrum = init_Spectrum.FindKernel("CalculateInitialSpectrum");
        K_Conjugate_Spectrum = init_Spectrum.FindKernel("CalculateConjugatedSpectrum");//共轭频谱

        K_Timed_Spectrum = timed_Spectrum.FindKernel("CalculateAmplitudes");
        K_Result_Texs = tex_Merge.FindKernel("FillResultTextures");

        paramsBuffer = new ComputeBuffer(2, 8 * sizeof(float));
        initialSpectrum = FastFourierTransform.CreateRenderTexture(size, RenderTextureFormat.ARGBFloat);
        precomputedData = FastFourierTransform.CreateRenderTexture(size, RenderTextureFormat.ARGBFloat);
        //最终渲染输出 用
        displacement = FastFourierTransform.CreateRenderTexture(size, RenderTextureFormat.ARGBFloat);
        derivatives = FastFourierTransform.CreateRenderTexture(size, RenderTextureFormat.ARGBFloat, true);
        turbulence = FastFourierTransform.CreateRenderTexture(size, RenderTextureFormat.ARGBFloat, true);

        //R-G 通道
        buffer = FastFourierTransform.CreateRenderTexture(size);//<256,256>
        DxDz = FastFourierTransform.CreateRenderTexture(size);
        DyDxz = FastFourierTransform.CreateRenderTexture(size);
        DyxDyz = FastFourierTransform.CreateRenderTexture(size);
        DxxDzz = FastFourierTransform.CreateRenderTexture(size);
    }

    public void Dispose()
    {
        paramsBuffer?.Release();
    }

    public void CalculateInitials(WavesSettings wavesSettings, float lengthScale,float cutoffLow, float cutoffHigh)
    {
        lambda = wavesSettings.lambda;

        init_Spectrum.SetInt(ID_Size, size);                  //256
        init_Spectrum.SetFloat(ID_Length_Scale, lengthScale); //250,17,5
        init_Spectrum.SetFloat(ID_Cutoff_High, cutoffHigh);   //0.0001
        init_Spectrum.SetFloat(ID_Cutoff_Low, cutoffLow);     //2*Pi*6/17
        wavesSettings.SetParametersToShader(init_Spectrum, K_Initial_Spectrum, paramsBuffer);   //wave 能量谱参数

        init_Spectrum.SetTexture(K_Initial_Spectrum, ID_H0K, buffer);                           //输出
        init_Spectrum.SetTexture(K_Initial_Spectrum, ID_Precompute_Data, precomputedData);      //输出
        init_Spectrum.SetTexture(K_Initial_Spectrum, ID_Noise, gaussianNoise);
        init_Spectrum.Dispatch(K_Initial_Spectrum, group, group, 1);//<32,32,1>

        init_Spectrum.SetTexture(K_Conjugate_Spectrum, ID_H0, initialSpectrum);               //输出
        init_Spectrum.SetTexture(K_Conjugate_Spectrum, ID_H0K, buffer);                       //输入
        init_Spectrum.Dispatch(K_Conjugate_Spectrum, group,group, 1);//<32,32,1>
    }

    public void CalculateWavesAtTime(float time)
    {
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_Dx_Dz, DxDz);                          //输出
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_Dy_Dxz, DyDxz);                        //输出
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_Dyx_Dyz, DyxDyz);                      //输出
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_Dxx_Dzz, DxxDzz);                      //输出
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_H0, initialSpectrum);                  //输入
        timed_Spectrum.SetTexture(K_Timed_Spectrum, ID_Precompute_Data, precomputedData);    //输入
        timed_Spectrum.SetFloat(ID_Time, time);
        timed_Spectrum.Dispatch(K_Timed_Spectrum, group, group, 1);//<32,32,1>

        // Calculating IFFTs of complex amplitudes
        fft.IFFT2D(DxDz, buffer);       //顶点位移 输入,输出
        fft.IFFT2D(DyDxz, buffer);      //顶点位移,扰动
        fft.IFFT2D(DyxDyz, buffer);     //法线
        fft.IFFT2D(DxxDzz, buffer);     //法线,扰动

        // Filling displacement and normals textures
        tex_Merge.SetFloat("DeltaTime", Time.deltaTime);
        //输入
        tex_Merge.SetTexture(K_Result_Texs, ID_Dx_Dz, DxDz);
        tex_Merge.SetTexture(K_Result_Texs, ID_Dy_Dxz, DyDxz);
        tex_Merge.SetTexture(K_Result_Texs, ID_Dyx_Dyz, DyxDyz);
        tex_Merge.SetTexture(K_Result_Texs, ID_Dxx_Dzz, DxxDzz);
        //输出
        tex_Merge.SetTexture(K_Result_Texs, ID_Displacement, displacement); //顶点位移
        tex_Merge.SetTexture(K_Result_Texs, ID_Derivatives, derivatives);   //法线
        tex_Merge.SetTexture(K_Result_Texs, ID_Turbulence, turbulence);     //扰动
        tex_Merge.SetFloat(ID_Lambda, lambda);
        tex_Merge.Dispatch(K_Result_Texs,group, group, 1);

        derivatives.GenerateMips();
        turbulence.GenerateMips();
    }

    // Kernel IDs:
    int K_Initial_Spectrum;
    int K_Conjugate_Spectrum;
    int K_Timed_Spectrum;
    int K_Result_Texs;

    // Property IDs
    readonly int ID_Size = Shader.PropertyToID("Size");                 //256
    readonly int ID_Length_Scale = Shader.PropertyToID("LengthScale");  //250,17,5
    readonly int ID_Cutoff_High = Shader.PropertyToID("CutoffHigh");
    readonly int ID_Cutoff_Low = Shader.PropertyToID("CutoffLow");

    readonly int ID_Noise = Shader.PropertyToID("Noise");
    readonly int ID_H0 = Shader.PropertyToID("H0");
    readonly int ID_H0K = Shader.PropertyToID("H0K");
    readonly int ID_Precompute_Data = Shader.PropertyToID("WavesData");
    readonly int ID_Time = Shader.PropertyToID("Time");

    readonly int ID_Dx_Dz = Shader.PropertyToID("Dx_Dz");
    readonly int ID_Dy_Dxz = Shader.PropertyToID("Dy_Dxz");
    readonly int ID_Dyx_Dyz = Shader.PropertyToID("Dyx_Dyz");
    readonly int ID_Dxx_Dzz = Shader.PropertyToID("Dxx_Dzz");
    readonly int ID_Lambda = Shader.PropertyToID("Lambda");

    readonly int ID_Displacement = Shader.PropertyToID("Displacement");
    readonly int ID_Derivatives = Shader.PropertyToID("Derivatives");
    readonly int ID_Turbulence = Shader.PropertyToID("Turbulence"); 
}
