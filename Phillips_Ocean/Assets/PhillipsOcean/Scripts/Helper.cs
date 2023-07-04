using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Helper
{
	public static GameObject[] CreateGrid(int m_numGridsX,int m_numGridsZ,Material m_mat,Mesh m_mesh,float m_length,Transform parent)
    {
		GameObject[] m_oceanGrid = new GameObject[m_numGridsX * m_numGridsZ];

		for (int x = 0; x < m_numGridsX; x++)
		{
			for (int z = 0; z < m_numGridsZ; z++)
			{
				int idx = x + z * m_numGridsX;

				m_oceanGrid[idx] = new GameObject("Ocean grid " + idx.ToString());
				m_oceanGrid[idx].AddComponent<MeshFilter>();
				m_oceanGrid[idx].AddComponent<MeshRenderer>();
				m_oceanGrid[idx].GetComponent<Renderer>().material = m_mat;
				m_oceanGrid[idx].GetComponent<MeshFilter>().mesh = m_mesh;
				m_oceanGrid[idx].transform.Translate(new Vector3(x * m_length - m_numGridsX * m_length / 2, 0.0f, z * m_length - m_numGridsZ * m_length / 2));
				m_oceanGrid[idx].transform.parent = parent;

			}
		}
		return m_oceanGrid;
	}
	public static Mesh MakeMesh(int size)
	{

		Vector3[] vertices = new Vector3[size * size];
		Vector2[] texcoords = new Vector2[size * size];
		Vector3[] normals = new Vector3[size * size];
		int[] indices = new int[size * size * 6];

		for (int x = 0; x < size; x++)
		{
			for (int y = 0; y < size; y++)
			{
				Vector2 uv = new Vector3((float)x / (float)(size - 1), (float)y / (float)(size - 1));
				Vector3 pos = new Vector3(x, 0.0f, y);
				Vector3 norm = new Vector3(0.0f, 1.0f, 0.0f);

				texcoords[x + y * size] = uv;
				vertices[x + y * size] = pos;
				normals[x + y * size] = norm;
			}
		}

		int num = 0;
		for (int x = 0; x < size - 1; x++)
		{
			for (int y = 0; y < size - 1; y++)
			{
				indices[num++] = x + y * size;
				indices[num++] = x + (y + 1) * size;
				indices[num++] = (x + 1) + y * size;

				indices[num++] = x + (y + 1) * size;
				indices[num++] = (x + 1) + (y + 1) * size;
				indices[num++] = (x + 1) + y * size;
			}
		}

		Mesh mesh = new Mesh();

		mesh.vertices = vertices;
		mesh.uv = texcoords;
		mesh.triangles = indices;
		mesh.normals = normals;

		return mesh;
	}
}
