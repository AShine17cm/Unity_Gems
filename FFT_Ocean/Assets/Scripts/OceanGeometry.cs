using System.Collections.Generic;
using UnityEngine;

public class OceanGeometry : MonoBehaviour
{
    public WavesGenerator wavesGenerator;
    public Material oceanMaterial;          //最终 合成，渲染

    Element center; //只一片
    Material mat;
    private void Start()
    {
        oceanMaterial.SetTexture("_Displacement_c0", wavesGenerator.cascade0.Displacement);
        oceanMaterial.SetTexture("_Derivatives_c0", wavesGenerator.cascade0.Derivatives);
        oceanMaterial.SetTexture("_Turbulence_c0", wavesGenerator.cascade0.Turbulence);

        oceanMaterial.SetTexture("_Displacement_c1", wavesGenerator.cascade1.Displacement);
        oceanMaterial.SetTexture("_Derivatives_c1", wavesGenerator.cascade1.Derivatives);
        oceanMaterial.SetTexture("_Turbulence_c1", wavesGenerator.cascade1.Turbulence);

        oceanMaterial.SetTexture("_Displacement_c2", wavesGenerator.cascade2.Displacement);
        oceanMaterial.SetTexture("_Derivatives_c2", wavesGenerator.cascade2.Derivatives);
        oceanMaterial.SetTexture("_Turbulence_c2", wavesGenerator.cascade2.Turbulence);

        mat = new Material(oceanMaterial);
        mat.EnableKeyword("CLOSE");   //3个层级，平滑，波光粼粼
        //mat.DisableKeyword("CLOSE");
        //mat.EnableKeyword("MID");

        int k =128;
        float lengthScale = 1f;
        center = InstantiateElement("Center", CreatePlaneMesh(2 * k, 2 * k, lengthScale), mat);
        //
        float scale = 0.1f;
        center.Transform.position = Vector3.zero;
        center.Transform.localScale = new Vector3(scale, 1, scale);
    }

    private void Update()
    {
        //Shader.SetGlobalFloat("LengthScale0", lengthWave);
    }

    Element InstantiateElement(string name, Mesh mesh, Material mat)
    {
        GameObject go = new GameObject();
        go.name = name;
        go.transform.SetParent(transform);
        go.transform.localPosition = Vector3.zero;
        MeshFilter meshFilter = go.AddComponent<MeshFilter>();
        meshFilter.mesh = mesh;
        MeshRenderer meshRenderer = go.AddComponent<MeshRenderer>();
        meshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        meshRenderer.receiveShadows = true;
        meshRenderer.motionVectorGenerationMode = MotionVectorGenerationMode.Camera;
        meshRenderer.material = mat;
        meshRenderer.allowOcclusionWhenDynamic = false;
        return new Element(go.transform, meshRenderer);
    }

    /* 一个简单的平面 width 是段数 */
    Mesh CreatePlaneMesh(int width, int height, float lengthScale)
    {
        Mesh mesh = new Mesh();
        mesh.name = "Clipmap plane";
        if ((width + 1) * (height + 1) >= 256 * 256)
            mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;//最大 顶点数

        Vector3[] vertices = new Vector3[(width + 1) * (height + 1)];
        Vector3[] normals = new Vector3[(width + 1) * (height + 1)];
        int[] triangles = new int[width * height * 2 * 3];

        for (int i = 0; i < height + 1; i++)
        {
            for (int j = 0; j < width + 1; j++)
            {
                int x = j;
                int z = i;
                vertices[j + i * (width + 1)] = new Vector3(x, 0, z) * lengthScale;// x z 平面
                normals[j + i * (width + 1)] = Vector3.up;
            }
        }

        int tris = 0;
        for (int i = 0; i < height; i++)
        {
            for (int j = 0; j < width; j++)
            {
                int k = j + i * (width + 1);
                if ((i + j ) % 2 == 0)
                {
                    triangles[tris++] = k;
                    triangles[tris++] = k + width + 1;
                    triangles[tris++] = k + width + 2;

                    triangles[tris++] = k;
                    triangles[tris++] = k + width + 2;
                    triangles[tris++] = k + 1;
                }
                else
                {
                    triangles[tris++] = k;
                    triangles[tris++] = k + width + 1;
                    triangles[tris++] = k + 1;

                    triangles[tris++] = k + 1;
                    triangles[tris++] = k + width + 1;
                    triangles[tris++] = k + width + 2;
                }
            }
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.normals = normals;
        return mesh;
    }

    class Element
    {
        public Transform Transform;
        public MeshRenderer MeshRenderer;

        public Element(Transform transform, MeshRenderer meshRenderer)
        {
            Transform = transform;
            MeshRenderer = meshRenderer;
        }
    }
}


