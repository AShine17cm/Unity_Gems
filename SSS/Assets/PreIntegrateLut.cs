using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

//预计算 皮肤的  LUT
public class PreIntegrateLut : MonoBehaviour
{
    public Texture2D tex;
    public int width = 512;
    public int height = 512;
    public bool doTest = false;

    private void Update()
    {
        if(doTest)
        { 
            doTest = false;
            tex = new Texture2D(width, height);
            PreIntegrateSSSLUT(tex);

            byte[] bytes= tex.EncodeToPNG();
            string targetPath = Application.dataPath + "/SkinLut" + ".tga";
            FileStream fs = File.Create(targetPath);
            fs.Write(bytes, 0, bytes.Length);
            fs.Flush();
            fs.Close();

            AssetDatabase.Refresh();
        }
    }
    private void PreIntegrateSSSLUT(Texture2D texture)
    {
        int height = texture.height;
        int width = texture.width;
        for (int j = 0; j < height; j++)//每一个曲率
        {
            //2 r sin(x/2)
            float oneOverR = 2.0f * 1 / ((j + 1) / (float)height);  //从上到下 曲率变小
            for(int i=0;i<width;i++)//每个灯光入射角
            {
                float dotNL = Mathf.Lerp(-1, 1, i / (float)width);  //法线 与 光的夹角

                Vector3 diff = Integrate(dotNL, oneOverR);

                texture.SetPixel(i, j, new Color(diff.x, diff.y, diff.z, 1));
            }
        }
        texture.Apply();
    }
    private Vector3 Integrate(float cosTheta,float skinRadius)
    {
        float theta = Mathf.Acos(cosTheta);//dot NL
        Vector3 totalWeights = Vector3.zero;
        Vector3 totalLight = Vector3.zero;

        float a = -(Mathf.PI / 2.0f);
        const float inc = 0.05f;

        //skinRadius = 1 / skinRadius;

        while(a<=(Mathf.PI/2.0f))// 半球积分    -Pi/2,Pi/2
        {
            float sampleAngle = theta + a;  
            float diffuse = Mathf.Clamp01(Mathf.Cos(sampleAngle));
            float sampleDist = Mathf.Abs(2.0f * skinRadius * Mathf.Sin(a * 0.5f));//角度转换距离因子

            Vector3 weights = Guassian(sampleDist);

            totalWeights =totalWeights+ weights;
            totalLight =totalLight+  weights*diffuse;

            a += inc;//半球 步进
        }
        Vector3 result = new Vector3(totalLight.x / totalWeights.x, totalLight.y / totalWeights.y, totalLight.z / totalWeights.z);
        return result;
    }

    Vector3 Guassian(float distance)
    {
        float neg_r_2 = -distance * distance;
        Vector3 v1 = new Vector3(0.233f, 0.455f, 0.649f);//r,g,b通道不同的权重
        Vector3 v2 = new Vector3(0.100f, 0.336f, 0.344f);
        Vector3 v3 = new Vector3(0.118f, 0.198f, 0.000f);
        Vector3 v4 = new Vector3(0.113f, 0.007f, 0.007f);
        Vector3 v5 = new Vector3(0.358f, 0.004f, 0.000f);
        Vector3 v6 = new Vector3(0.078f, 0.000f, 0.000f);

        Vector3 rgb = Vector3.zero;
        rgb += v1 * G2(neg_r_2, 0.0064f);
        rgb += v2 * G2(neg_r_2, 0.0484f);
        rgb += v3 * G2(neg_r_2, 0.1870f);
        rgb += v4 * G2(neg_r_2, 0.5670f);
        rgb += v5 * G2(neg_r_2, 1.9900f);
        rgb += v6 * G2(neg_r_2, 7.4100f);

        return Uncharted2Tonemap_V3(rgb);
    }
    //G2 高斯公式，v 方差, 
    float G2(float neg_r_2,float v)
    {
        float v2 = 2.0f * v;
        return 1.0f / (v2 * Mathf.PI) * Mathf.Exp(neg_r_2 / v2);
    }
    //对积分结果做 Tone-Mapping
    Vector3 Uncharted2Tonemap_V3(Vector3 rgb)
    {
        float exposureBias = 2.0f;

        rgb = rgb * exposureBias;
        float r = Uncharted2Tonemap(rgb.x);
        float g = Uncharted2Tonemap(rgb.y);
        float b = Uncharted2Tonemap(rgb.z);

        float W = 11.2f;
        float whiteScale = Uncharted2Tonemap(11.2f);//白平衡 ?

        //Vector3 color = new Vector3(r, g, b) * whiteScale;

        r = Mathf.Pow(r * whiteScale, 1 / 2.2f);
        g = Mathf.Pow(g * whiteScale, 1 / 2.2f);
        b = Mathf.Pow(b * whiteScale, 1 / 2.2f);

        return new Vector3(r, g, b);
    }
    float Uncharted2Tonemap(float x)
    {
        float A = 0.15f;
        float B = 0.50f;
        float C = 0.10f;
        float D = 0.20f;
        float E = 0.02f;
        float F = 0.30f;
        float W = 11.2f;
        float up = x * (x * A +  C * B) + D * E;
        float deto = x * (x * A + B) + D * F;
        return up / deto - E / F;
    }
}
