using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum TileKind
{
    None = 0,
    Flat = 1,
    Ramp = 2,
    Corner = 3,
}
public class SimpleMap
{
    public const float size = 1f;
    public const float size_h = 0.5f;
    public const float height = 0.5f;

    public int tileCount;
    public TileKind[][] kinds;
    public DirKind[][] dirs;
    public HeightLevel[][] heights;
    public Tile[][] tiles;
    public int[][] vals;
    public SimpleMap(int tileCount)
    {
        this.tileCount = tileCount;
        kinds = new TileKind[tileCount][];
        dirs = new DirKind[tileCount][];
        heights = new HeightLevel[tileCount][];
        tiles = new Tile[tileCount][];
        vals = new int[tileCount][];
        for (int i = 0; i < tileCount; i++)
        {
            kinds[i] = new TileKind[tileCount];
            dirs[i] = new DirKind[tileCount];
            heights[i] = new HeightLevel[tileCount];
            tiles[i] = new Tile[tileCount];
            vals[i] = new int[tileCount];
        }
    }
    public void Generate()
    {
        int toVal = -1;
        for (int i = 0; i < tileCount; i++)
        {
            for (int k = 0; k < tileCount; k++)
            {
                vals[i][k] = toVal;
            }
        }
        int maxW = tileCount / 2;
        int minW = tileCount / 8;
        int w = Random.Range(minW, maxW);
        int minH = 3;
        int maxH = tileCount / 16;
        int h = Random.Range(minH, maxH);

        Scan(HeightLevel.Three, w, h);

        maxW = tileCount  / 4;
        minW = tileCount / 8;
        minH = 4;
        maxH = tileCount / 6;
        w = Random.Range(minW, maxW);
        h = Random.Range(minH, maxH);
        Scan(HeightLevel.Two, w, h);

        w = Random.Range(minW, maxW);
        h = Random.Range(minH, maxH);
        Scan(HeightLevel.Two, w, h);

        maxW = tileCount  / 2;
        minW = tileCount / 8;
        minH = 4;
        maxH = tileCount / 4;
        w = Random.Range(minW, maxW);
        h = Random.Range(minH, maxH);
        Scan(HeightLevel.One, w, h);

        maxW = tileCount  / 2;
        minW = tileCount / 16;
        minH = 4;
        maxH = tileCount / 6;
        w = Random.Range(minW, maxW);
        h = Random.Range(minH, maxH);
        Scan(HeightLevel.One, w, h);

        Scan(HeightLevel.One, w, h);

        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[x][z];
                if (TileKind.Flat == kind)
                {
                    HeightLevel level = heights[x][z];
                    GameObject tmp = SimpleGenerator.Instance.tiles[kind];
                    GameObject go = GameObject.Instantiate<GameObject>(tmp);
                    Tile tile = go.GetComponent<Tile>();
                    tile.heightLev = level;
                    tile.kind = kind;
                    go.SetActive(true);
                    Transform tr = go.transform;
                    float offset = (int)level * height;
                    tr.position = new Vector3(x, offset, z);
                    tr.rotation = Quaternion.identity;
                    tiles[x][z] = tile;
                }
            }
        }
        FillGap(HeightLevel.Three);
        FillGap(HeightLevel.Two);
        FillGap(HeightLevel.One);

        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[x][z];
                DirKind dir = dirs[x][z];
                if (TileKind.Ramp == kind)
                {
                    HeightLevel level = heights[x][z];
                    GameObject tmp = SimpleGenerator.Instance.tiles[kind];
                    GameObject go = GameObject.Instantiate<GameObject>(tmp);
                    Tile tile = go.GetComponent<Tile>();
                    tile.kind = kind;
                    tile.heightLev = level;
                    go.SetActive(true);
                    Transform tr = go.transform;
                    float offset = (int)level * height;
                    tr.position = new Vector3(x, offset, z);
                    Vector3 euler = Vector3.zero;
                    switch (dir)
                    {
                        case DirKind.Left:
                            euler = new Vector3(0, 270, 0);
                            break;
                        case DirKind.Right:
                            euler = new Vector3(0, 90, 0);
                            break;
                        case DirKind.Bottom:
                            euler = new Vector3(0, 180, 0);
                            break;
                        case DirKind.Top:
                            euler = Vector3.zero;
                            break;
                    }
                    tr.eulerAngles = euler;
                    tiles[x][z] = tile;
                }
            }
        }
    }
    void FillGap(HeightLevel ofLevel)
    {
        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[x][z];
                if (TileKind.Flat == kind)
                {
                    Tile tile = tiles[x][z];
                    tile.Fill(this, ofLevel, new Vector2Int(x, z));
                }
            }
        }
    }
    void Scan(HeightLevel level, int w, int h)
    {
        int atX = Random.Range(0, tileCount / 2);
        int atZ = Random.Range(0, tileCount / 2);
        int maxZ = Mathf.Min(atZ + h, tileCount);
        int maxX = Mathf.Min(atX + w, tileCount);

        for (int z = atZ; z < maxZ; z++)
        {
            for (int x = atX; x < maxX; x++)
            {
                if (vals[z][x] == 1) continue;

                kinds[z][x] = TileKind.Flat;
                dirs[z][x] = DirKind.None;
                heights[z][x] = level;
                vals[z][x] = 1;
            }
        }
        int gap = (int)level + 2;
        //ÁÚ½ÓÇøÓò
        atZ = Mathf.Max(0, atZ -gap);
        atX = Mathf.Max(0, atX -gap);
        maxZ = Mathf.Min(maxZ + gap, tileCount);
        maxX = Mathf.Min(maxX + gap, tileCount);
        for (int z = atZ; z < maxZ; z++)
        {
            for (int x = atX; x < maxX; x++)
            {
                if (vals[z][x] == 1) continue;
                //kinds[z][x] = TileKind.Flat;
                //dirs[z][x] = DirKind.None;
                //heights[z][x] = level;
                vals[z][x] = 1;
            }
        }
    }
    public void Clear()
    {

        for (int i = 0; i < tileCount; i++)
        {
            for (int k = 0; k < tileCount; k++)
            {
                kinds[i][k] = TileKind.None;
                dirs[i][k] = DirKind.None;
                heights[i][k] = HeightLevel.Zero;
                vals[i][k] = 0;
                Tile tile = tiles[i][k];
                if(tile!=null)
                GameObject.Destroy(tile.gameObject);
            }
        }
    }

}
