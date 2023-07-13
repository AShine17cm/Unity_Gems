using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Map
{
    const float size = 1f;
    const float size_h = 0.5f;

    int tileCount;
    int[][] idArray;
    int[][] offsetArray;
    GameObject[][] goArray;
    List<Vector2Int> coords;
    Probabi probs = new Probabi();
    enum State
    {
        None=0,
        Reverse=1,
        Continue=2,
    }
    public void Init(int tileCount)
    {
        this.tileCount = tileCount;
        idArray = new int[tileCount][];
        offsetArray = new int[tileCount][];
        goArray = new GameObject[tileCount][];
        for (int i = 0; i < tileCount; i++)
        {
            idArray[i] = new int[tileCount];
            offsetArray[i] = new int[tileCount];
            goArray[i] = new GameObject[tileCount];
        }
        //转换成一维数组
        coords = new List<Vector2Int>(tileCount * tileCount);
        for(int k = 0; k < tileCount; k++)
        {
            int atX, atZ;
            for(int x = 0; x < k; x++)//row
            {
                atZ = k;
                coords.Add(new Vector2Int(x, atZ));
            }
            for(int z = 0; z < k; z++)
            {
                atX = k;
                coords.Add(new Vector2Int(atX, z));
            }
            coords.Add(new Vector2Int(k, k));//corner
        }
    }
    public void Generate()
    {
        int idx = 0;
        int total = coords.Count;
        int xx = -1;
        int maxReverse = tileCount*2;
        State state = State.None;
        Vector2Int breakCoord = Vector2Int.zero;
        while (idx < total)
        {
            if (state == State.Reverse)
            {

            }
            Vector2Int coord = coords[idx];
            bool isOK = Insert(coord);
            if (isOK)
            {
                idx += 1;
                if (State.Reverse == state)//结束 回退
                {
                    if (coord == breakCoord)
                    {
                        state = State.None;
                        xx = 0;
                    }
                }else if (State.Continue == state)
                {
                    InsertError(coord);
                    if (coord == breakCoord)
                    {
                        state = State.None;
                        xx = 0;
                    }
                }
            }
            else
            {
                idx -= 1;
                if (State.None == state)
                {
                    state = State.Reverse;
                    breakCoord = coord;
                }
                else
                {
                    xx += 1;
                    if (xx > maxReverse)
                    {
                        InsertError(coord);
                        state = State.Continue;
                        Debug.Log("<Color=red> 有错误 ? </Color>");
                    }
                }
            }
        }
        for(int z = 0; z < tileCount; z++)
        {
            for(int x = 0; x < tileCount; x++)
            {
                int id = idArray[x][z];
                float offset = offsetArray[x][z];
                offset = offset * GlobalVariants.height;
                if (id == -100)
                {
                    GameObject gox = GameObject.Instantiate<GameObject>(GlobalVariants.errorGo);
                    gox.SetActive(true);
                    gox.transform.position = new Vector3(x, 0, z);
                    goArray[x][z] = gox;
                    continue;
                }
                Part part = GlobalVariants.variants[id];
                GameObject go= GameObject.Instantiate<GameObject>(part.go);
                go.SetActive(true);
                go.transform.position = new Vector3(x, offset, z);
                goArray[x][z] = go;
            }
        }
    }
    List<int> tmp = new List<int>(64);
    bool Insert(Vector2Int coord)
    {
        int atX = coord.x;
        int atZ = coord.y;

        int left_X = atX - 1;
        int top_Z = atZ - 1;

        int id_left = -1;
        int id_top = -1;

        int idx_Random = -1;
        if (left_X >= 0)
        {
            id_left = idArray[left_X][atZ];
        }
        if (top_Z >= 0)
        {
            id_top = idArray[atX][top_Z];
        }
        if (atX == 0 && atZ == 0)
        {
            tmp.Clear();
            tmp.AddRange(GlobalVariants.variants.Keys);
            idx_Random = Random.Range(0, tmp.Count);
            idArray[0][0] = 0;// tmp[idx_Random];
            offsetArray[0][0] = 0;
            return true;
        }
        else
        {
            Part.Cross(probs, id_left, id_top);
        }
        if (probs.ids.Count <= 0)
        {
            Debug.Log("XXX");
            return false;
        }
        idx_Random = Random.Range(0, probs.ids.Count);

        idArray[atX][atZ] = probs.ids[idx_Random];
        offsetArray[atX][atZ] = probs.offset[idx_Random];
        return true;
    }
    void InsertError(Vector2Int coord)
    {
        idArray[coord.x][coord.y] = -100;
        offsetArray[coord.x][coord.y] = 0;
    }
    public void Clear()
    {
        for (int i = 0; i < tileCount; i++)
        {
            int[] id_row = idArray[i];
            GameObject[] go_row = goArray[i];
            for (int k = 0; k < tileCount; k++)
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
