using System;
using UnityEngine;

public class WavesCascade
{
    public RenderTexture Displacement => displacement;
    public RenderTexture Derivatives => derivatives;
    public RenderTexture Turbulence => turbulence;

    readonly int size;
    readonly ComputeShader init_Spectrum;       //初始化函数
    readonly ComputeShader timed_Spectrum;
    readonly ComputeShader tex_Merge;
    readonly FastFourierTransform fft;          //外部构造
    readonly Texture2D gaussianNoise;


    readonly ComputeBuffer paramsBuffer;
    readonly RenderTexture initialSpectrum; 
    readonly RenderTexture precomputedData;
    //最终渲染输出 用
    readonly RenderTexture displacement;
    readonly RenderTexture derivatives;
    readonly RenderTexture turbulence;
    
    readonly RenderTexture buffer;
    readonly RenderTexture DxDz;
    readonly RenderTexture DyDxz;
    readonly RenderTexture DyxDyz;
    readonly RenderTexture DxxDzz;


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

        //核函数
        K_Initial_Spectrum = init_Spectrum.FindKernel("CalculateInitialSpectrum");
        K_Conjugate_Spectrum = init_Spectrum.FindKernel("CalculateConjugatedSpectrum");
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
        buffer = FastFourierTransform.CreateRenderTexture(size);
        DxDz = FastFourierTransform.CreateRenderTexture(size);
        DyDxz = FastFourierTransform.CreateRenderTexture(size);
        DyxDyz = FastFourierTransform.CreateRenderTexture(size);
        DxxDzz = FastFourierTransform.CreateRenderTexture(size);
    }

    public void Dispose()
    {
        paramsBuffer?.Release();
    }

    public void CalculateInitials(WavesSettings wavesSettings, float lengthScale,
                                  float cutoffLow, float cutoffHigh)
    {
        lambda = wavesSettings.lambda;

        init_Spectrum.SetInt(SIZE_PROP, size);
        init_Spectrum.SetFloat(LENGTH_SCALE_PROP, lengthScale);
        init_Spectrum.SetFloat(CUTOFF_HIGH_PROP, cutoffHigh);
        init_Spectrum.SetFloat(CUTOFF_LOW_PROP, cutoffLow);
        wavesSettings.SetParametersToShader(init_Spectrum, K_Initial_Spectrum, paramsBuffer);

        init_Spectrum.SetTexture(K_Initial_Spectrum, H0K_PROP, buffer);
        init_Spectrum.SetTexture(K_Initial_Spectrum, PRECOMPUTED_DATA_PROP, precomputedData);
        init_Spectrum.SetTexture(K_Initial_Spectrum, NOISE_PROP, gaussianNoise);
        init_Spectrum.Dispatch(K_Initial_Spectrum, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);

        init_Spectrum.SetTexture(K_Conjugate_Spectrum, H0_PROP, initialSpectrum);
        init_Spectrum.SetTexture(K_Conjugate_Spectrum, H0K_PROP, buffer);
        init_Spectrum.Dispatch(K_Conjugate_Spectrum, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);
    }

    public void CalculateWavesAtTime(float time)
    {
        // Calculating complex amplitudes
        timed_Spectrum.SetTexture(K_Timed_Spectrum, Dx_Dz_PROP, DxDz);
        timed_Spectrum.SetTexture(K_Timed_Spectrum, Dy_Dxz_PROP, DyDxz);
        timed_Spectrum.SetTexture(K_Timed_Spectrum, Dyx_Dyz_PROP, DyxDyz);
        timed_Spectrum.SetTexture(K_Timed_Spectrum, Dxx_Dzz_PROP, DxxDzz);
        timed_Spectrum.SetTexture(K_Timed_Spectrum, H0_PROP, initialSpectrum);
        timed_Spectrum.SetTexture(K_Timed_Spectrum, PRECOMPUTED_DATA_PROP, precomputedData);
        timed_Spectrum.SetFloat(TIME_PROP, time);
        timed_Spectrum.Dispatch(K_Timed_Spectrum, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);

        // Calculating IFFTs of complex amplitudes
        fft.IFFT2D(DxDz, buffer, true, false, true);
        fft.IFFT2D(DyDxz, buffer, true, false, true);
        fft.IFFT2D(DyxDyz, buffer, true, false, true);
        fft.IFFT2D(DxxDzz, buffer, true, false, true);

        // Filling displacement and normals textures
        tex_Merge.SetFloat("DeltaTime", Time.deltaTime);

        tex_Merge.SetTexture(K_Result_Texs, Dx_Dz_PROP, DxDz);
        tex_Merge.SetTexture(K_Result_Texs, Dy_Dxz_PROP, DyDxz);
        tex_Merge.SetTexture(K_Result_Texs, Dyx_Dyz_PROP, DyxDyz);
        tex_Merge.SetTexture(K_Result_Texs, Dxx_Dzz_PROP, DxxDzz);
        tex_Merge.SetTexture(K_Result_Texs, DISPLACEMENT_PROP, displacement);
        tex_Merge.SetTexture(K_Result_Texs, DERIVATIVES_PROP, derivatives);
        tex_Merge.SetTexture(K_Result_Texs, TURBULENCE_PROP, turbulence);
        tex_Merge.SetFloat(LAMBDA_PROP, lambda);
        tex_Merge.Dispatch(K_Result_Texs, size / WORK_GROUPS_X, size / WORK_GROUPS_Y, 1);

        derivatives.GenerateMips();
        turbulence.GenerateMips();
    }

    const int WORK_GROUPS_X = 8;
    const int WORK_GROUPS_Y = 8;

    // Kernel IDs:
    int K_Initial_Spectrum;
    int K_Conjugate_Spectrum;
    int K_Timed_Spectrum;
    int K_Result_Texs;

    // Property IDs
    readonly int SIZE_PROP = Shader.PropertyToID("Size");
    readonly int LENGTH_SCALE_PROP = Shader.PropertyToID("LengthScale");
    readonly int CUTOFF_HIGH_PROP = Shader.PropertyToID("CutoffHigh");
    readonly int CUTOFF_LOW_PROP = Shader.PropertyToID("CutoffLow");

    readonly int NOISE_PROP = Shader.PropertyToID("Noise");
    readonly int H0_PROP = Shader.PropertyToID("H0");
    readonly int H0K_PROP = Shader.PropertyToID("H0K");
    readonly int PRECOMPUTED_DATA_PROP = Shader.PropertyToID("WavesData");
    readonly int TIME_PROP = Shader.PropertyToID("Time");

    readonly int Dx_Dz_PROP = Shader.PropertyToID("Dx_Dz");
    readonly int Dy_Dxz_PROP = Shader.PropertyToID("Dy_Dxz");
    readonly int Dyx_Dyz_PROP = Shader.PropertyToID("Dyx_Dyz");
    readonly int Dxx_Dzz_PROP = Shader.PropertyToID("Dxx_Dzz");
    readonly int LAMBDA_PROP = Shader.PropertyToID("Lambda");

    readonly int DISPLACEMENT_PROP = Shader.PropertyToID("Displacement");
    readonly int DERIVATIVES_PROP = Shader.PropertyToID("Derivatives");
    readonly int TURBULENCE_PROP = Shader.PropertyToID("Turbulence"); 
}
