using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Map
{
    int tileCount;
    int[][] idArray;
    GameObject[][] goArray;

    public void Init(int tileCount)
    {
        this.tileCount = tileCount;
        idArray = new int[tileCount][];
        goArray = new GameObject[tileCount][];
        for (int i = 0; i < tileCount; i++)
        {
            idArray[i] = new int[tileCount];
            goArray[i] = new GameObject[tileCount];
        }
    }
    public void Generate()
    {
        
    }
    void Step(int k)
    {

    }
    public void Clear()
    {
        for (int i = 0; i < tileCount; i++)
        {
            int[] id_row = idArray[i];
            GameObject[] go_row = goArray[i];
            for(int k = 0; k < tileCount; k++)
            {
                if (go_row[k] != null)
                {
                    GameObject.Destroy(go_row[k]);
                    go_row[k] = null;
                }
            }
        }
    }
}
