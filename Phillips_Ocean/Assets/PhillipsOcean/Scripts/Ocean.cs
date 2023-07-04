using UnityEngine;
using System;
using System.Collections;
using System.Threading;

namespace PhillipsOcean
{
    /// <summary>
    /// The ocean game object.
    /// Is responsible for creating the ocean mesh and other
    /// resources.
    /// </summary>
    public class Ocean : MonoBehaviour
    {

        const float GRAVITY = 9.81f;
        public Material mat;
        public int numGridsX = 8;
        public int numGridsZ = 8;

        //fourier 点数, 必须2的幂次方
        public int N = 64;
        public float length = 64;     //一个面片的大小

        public  float waveAmp = 0.0002f;
        public Vector2 windSpeed = new Vector2(32.0f, 32.0f);

        GameObject[] oceanGrid;
        Mesh mesh;//一块 Mesh

        int N_1;// 64+1

        Vector2 windDir;
        FourierCPU fourier;

        //傅里叶变换的中间结果
        Vector2[,] heightBuffer;
        Vector4[,] slopeBuffer, displacementBuffer;

        /// <summary>
        /// Holds the spectrum which will be then be transformed into
        /// the wave heights/slopes.
        /// </summary>
        Vector2[] m_spectrum, m_spectrum_conj;

        /// <summary>
        /// 
        /// </summary>
        Vector3[] m_position;
        Vector3[] m_vertices;
        Vector3[] m_normals;

        /// <summary>
        /// Just holds so data for the spectrum that can be precomputed.
        /// </summary>
        float[] dispersionTable;//散布 中心分布的 正比于波数的二维表

        /// <summary>
        /// The fresnel look up table.
        /// </summary>
        Texture2D m_fresnelLookUp;

        /// <summary>
        /// Has the thread generating the data finished.
        /// </summary>
        volatile bool done = true;

        void Start()
        {
            N_1 = N + 1;

            fourier = new FourierCPU(N);

            windDir = new Vector2(windSpeed.x, windSpeed.y);
            windDir.Normalize();

            dispersionTable = new float[N_1 * N_1];

            for (int m_prime = 0; m_prime < N_1; m_prime++)
            {
                for (int n_prime = 0; n_prime < N_1; n_prime++)
                {
                    int index = m_prime * N_1 + n_prime;
                    dispersionTable[index] = Dispersion(n_prime, m_prime);
                }
            }

            heightBuffer = new Vector2[2, N * N];
            slopeBuffer = new Vector4[2, N * N];
            displacementBuffer = new Vector4[2, N * N];

            m_spectrum = new Vector2[N_1 * N_1];
            m_spectrum_conj = new Vector2[N_1 * N_1];

            m_position = new Vector3[N_1 * N_1];
            m_vertices = new Vector3[N_1 * N_1];
            m_normals = new Vector3[N_1 * N_1];

            mesh = Helper.MakeMesh(N_1);

            oceanGrid = Helper.CreateGrid(numGridsX, numGridsZ, mat, mesh, length, transform);

            UnityEngine.Random.InitState(0);

            Vector3[] vertices = mesh.vertices;

            for (int m_prime = 0; m_prime < N_1; m_prime++)
            {
                for (int n_prime = 0; n_prime < N_1; n_prime++)
                {
                    int index = m_prime * N_1 + n_prime;

                    m_spectrum[index] = GetSpectrum(n_prime, m_prime);

                    m_spectrum_conj[index] = GetSpectrum(-n_prime, -m_prime);
                    m_spectrum_conj[index].y *= -1.0f;

                    m_position[index].x = vertices[index].x = n_prime * length / N;
                    m_position[index].y = vertices[index].y = 0.0f;
                    m_position[index].z = vertices[index].z = m_prime * length / N;

                }
            }

            mesh.vertices = vertices;
            mesh.RecalculateBounds();

            CreateFresnelLookUp();
        }

        /// <summary>
        /// Create a fresnel lookup table. This is the formula
        /// to calculate a materials fresnel value based on 
        /// its refractive index. Since its a little math heavy
        /// a look up table is used rather than caculate it in 
        /// the shader. In practise this method does not look any better
        /// than cheaper approximations but is included out of interest.
        /// </summary>
        void CreateFresnelLookUp()
        {
            float nSnell = 1.34f; //Refractive index of water

            m_fresnelLookUp = new Texture2D(512, 1, TextureFormat.Alpha8, false);
            m_fresnelLookUp.filterMode = FilterMode.Bilinear;
            m_fresnelLookUp.wrapMode = TextureWrapMode.Clamp;
            m_fresnelLookUp.anisoLevel = 0;

            for (int x = 0; x < 512; x++)
            {
                float fresnel = 0.0f;
                float costhetai = (float)x / 511.0f;
                float thetai = Mathf.Acos(costhetai);
                float sinthetat = Mathf.Sin(thetai) / nSnell;
                float thetat = Mathf.Asin(sinthetat);

                if (thetai == 0.0f)
                {
                    fresnel = (nSnell - 1.0f) / (nSnell + 1.0f);
                    fresnel = fresnel * fresnel;
                }
                else
                {
                    float fs = Mathf.Sin(thetat - thetai) / Mathf.Sin(thetat + thetai);
                    float ts = Mathf.Tan(thetat - thetai) / Mathf.Tan(thetat + thetai);
                    fresnel = 0.5f * (fs * fs + ts * ts);
                }

                m_fresnelLookUp.SetPixel(x, 0, new Color(fresnel, fresnel, fresnel, fresnel));
            }

            m_fresnelLookUp.Apply();

            mat.SetTexture("_FresnelLookUp", m_fresnelLookUp);
        }

        /// <summary>
        /// Evaulate the waves for time period each update.
        /// </summary>
        void Update()
        {

            //If still running return.
            if (!done) return;

            //Set data generated form last calculations.
            mesh.vertices = m_vertices;
            mesh.normals = m_normals;
            mesh.RecalculateBounds();

            //Start new calculations for time period t.
            done = false;

            Nullable<float> time = Time.realtimeSinceStartup;

            ThreadPool.QueueUserWorkItem(new WaitCallback(RunThreaded), time);
        }

        /// <summary>
        /// Gets the spectrum vaule for grid position n,m. 
        /// </summary>
        Vector2 GetSpectrum(int n_prime, int m_prime)
        {
            Vector2 r = GaussianRandomVariable();
            return r * Mathf.Sqrt(PhillipsSpectrum(n_prime, m_prime) / 2.0f);
        }

        /// <summary>
        /// Random variable with a gaussian distribution.
        /// </summary>
        Vector2 GaussianRandomVariable()
        {
            float x1, x2, w;
            do
            {
                x1 = 2.0f * UnityEngine.Random.value - 1.0f;
                x2 = 2.0f * UnityEngine.Random.value - 1.0f;
                w = x1 * x1 + x2 * x2;
            }
            while (w >= 1.0f);

            w = Mathf.Sqrt((-2.0f * Mathf.Log(w)) / w);
            return new Vector2(x1 * w, x2 * w);
        }

        /// <summary>
        /// Gets the spectrum vaule for grid position n,m.
        /// </summary>
        float PhillipsSpectrum(int n_prime, int m_prime)
        {
            Vector2 k = new Vector2(Mathf.PI * (2 * n_prime - N) / length, Mathf.PI * (2 * m_prime - N) / length);
            float k_length = k.magnitude;
            if (k_length < 0.000001f) return 0.0f;

            float k_length2 = k_length * k_length;
            float k_length4 = k_length2 * k_length2;

            k.Normalize();

            float k_dot_w = Vector2.Dot(k, windDir);
            float k_dot_w2 = k_dot_w * k_dot_w * k_dot_w * k_dot_w * k_dot_w * k_dot_w;

            float w_length = windSpeed.magnitude;
            float L = w_length * w_length / GRAVITY;
            float L2 = L * L;

            float damping = 0.001f;
            float l2 = L2 * damping * damping;

            return waveAmp * Mathf.Exp(-1.0f / (k_length2 * L2)) / k_length4 * k_dot_w2 * Mathf.Exp(-k_length2 * l2);
        }

        float Dispersion(int n_prime, int m_prime)
        {
            float w_0 = 2.0f * Mathf.PI / 200.0f;
            float kx = Mathf.PI * (2 * n_prime - N) / length;
            float kz = Mathf.PI * (2 * m_prime - N) / length;
            return Mathf.Floor(Mathf.Sqrt(GRAVITY * Mathf.Sqrt(kx * kx + kz * kz)) / w_0) * w_0;
        }

        /// <summary>
        /// Inits the spectrum for time period t.
        /// </summary>
        Vector2 InitSpectrum(float t, int n_prime, int m_prime)
        {
            int index = m_prime * N_1 + n_prime;

            float omegat = dispersionTable[index] * t;

            float cos = Mathf.Cos(omegat);
            float sin = Mathf.Sin(omegat);

            float c0a = m_spectrum[index].x * cos - m_spectrum[index].y * sin;
            float c0b = m_spectrum[index].x * sin + m_spectrum[index].y * cos;

            float c1a = m_spectrum_conj[index].x * cos - m_spectrum_conj[index].y * -sin;
            float c1b = m_spectrum_conj[index].x * -sin + m_spectrum_conj[index].y * cos;

            return new Vector2(c0a + c1a, c0b + c1b);
        }

        /// <summary>
        /// Runs a threaded task
        /// </summary>
        void RunThreaded(object o)
        {

            Nullable<float> time = o as Nullable<float>;

            EvaluateWavesFFT(time.Value);

            done = true;

        }

        /// <summary>
        /// Evaluates the waves for time period t. Must be thread safe.
        /// </summary>
        void EvaluateWavesFFT(float t)
        {
            float kx, kz, len, lambda = -1.0f;
            int index, index1;

            for (int m_prime = 0; m_prime < N; m_prime++)
            {
                kz = Mathf.PI * (2.0f * m_prime - N) / length;

                for (int n_prime = 0; n_prime < N; n_prime++)
                {
                    kx = Mathf.PI * (2 * n_prime - N) / length;
                    len = Mathf.Sqrt(kx * kx + kz * kz);
                    index = m_prime * N + n_prime;

                    Vector2 c = InitSpectrum(t, n_prime, m_prime);

                    heightBuffer[1, index].x = c.x;
                    heightBuffer[1, index].y = c.y;

                    slopeBuffer[1, index].x = -c.y * kx;
                    slopeBuffer[1, index].y = c.x * kx;

                    slopeBuffer[1, index].z = -c.y * kz;
                    slopeBuffer[1, index].w = c.x * kz;

                    if (len < 0.000001f)
                    {
                        displacementBuffer[1, index].x = 0.0f;
                        displacementBuffer[1, index].y = 0.0f;
                        displacementBuffer[1, index].z = 0.0f;
                        displacementBuffer[1, index].w = 0.0f;
                    }
                    else
                    {
                        displacementBuffer[1, index].x = -c.y * -(kx / len);
                        displacementBuffer[1, index].y = c.x * -(kx / len);
                        displacementBuffer[1, index].z = -c.y * -(kz / len);
                        displacementBuffer[1, index].w = c.x * -(kz / len);
                    }
                }
            }

            fourier.PeformFFT(0, heightBuffer, slopeBuffer, displacementBuffer);

            int sign;
            float[] signs = new float[] { 1.0f, -1.0f };
            Vector3 n;

            for (int m_prime = 0; m_prime < N; m_prime++)
            {
                for (int n_prime = 0; n_prime < N; n_prime++)
                {
                    index = m_prime * N + n_prime;          // index into buffers
                    index1 = m_prime * N_1 + n_prime;    // index into vertices

                    sign = (int)signs[(n_prime + m_prime) & 1];

                    // height
                    m_vertices[index1].y = heightBuffer[1, index].x * sign;

                    // displacement
                    m_vertices[index1].x = m_position[index1].x + displacementBuffer[1, index].x * lambda * sign;
                    m_vertices[index1].z = m_position[index1].z + displacementBuffer[1, index].z * lambda * sign;

                    // normal
                    n = new Vector3(-slopeBuffer[1, index].x * sign, 1.0f, -slopeBuffer[1, index].z * sign);
                    n.Normalize();

                    m_normals[index1].x = n.x;
                    m_normals[index1].y = n.y;
                    m_normals[index1].z = n.z;

                    // for tiling
                    if (n_prime == 0 && m_prime == 0)
                    {
                        m_vertices[index1 + N + N_1 * N].y = heightBuffer[1, index].x * sign;

                        m_vertices[index1 + N + N_1 * N].x = m_position[index1 + N + N_1 * N].x + displacementBuffer[1, index].x * lambda * sign;
                        m_vertices[index1 + N + N_1 * N].z = m_position[index1 + N + N_1 * N].z + displacementBuffer[1, index].z * lambda * sign;

                        m_normals[index1 + N + N_1 * N].x = n.x;
                        m_normals[index1 + N + N_1 * N].y = n.y;
                        m_normals[index1 + N + N_1 * N].z = n.z;
                    }
                    if (n_prime == 0)
                    {
                        m_vertices[index1 + N].y = heightBuffer[1, index].x * sign;

                        m_vertices[index1 + N].x = m_position[index1 + N].x + displacementBuffer[1, index].x * lambda * sign;
                        m_vertices[index1 + N].z = m_position[index1 + N].z + displacementBuffer[1, index].z * lambda * sign;

                        m_normals[index1 + N].x = n.x;
                        m_normals[index1 + N].y = n.y;
                        m_normals[index1 + N].z = n.z;
                    }
                    if (m_prime == 0)
                    {
                        m_vertices[index1 + N_1 * N].y = heightBuffer[1, index].x * sign;

                        m_vertices[index1 + N_1 * N].x = m_position[index1 + N_1 * N].x + displacementBuffer[1, index].x * lambda * sign;
                        m_vertices[index1 + N_1 * N].z = m_position[index1 + N_1 * N].z + displacementBuffer[1, index].z * lambda * sign;

                        m_normals[index1 + N_1 * N].x = n.x;
                        m_normals[index1 + N_1 * N].y = n.y;
                        m_normals[index1 + N_1 * N].z = n.z;
                    }
                }
            }
        }//EvaluateWavesFFT
    }

}
