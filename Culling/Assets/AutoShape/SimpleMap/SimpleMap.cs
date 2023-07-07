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
    public const float height = 0.75f;

    public int tileCount;
    public TileKind[][] kinds;//z:row  x:col
    public DirKind[][] dirs;
    public HeightLevel[][] heights;
    public Tile[][] tiles;
    public int[][] vals;
    public int[][] corners;
    public SimpleMap(int tileCount)
    {
        this.tileCount = tileCount;
        kinds = new TileKind[tileCount][];
        dirs = new DirKind[tileCount][];
        heights = new HeightLevel[tileCount][];
        tiles = new Tile[tileCount][];
        vals = new int[tileCount][];
        corners = new int[tileCount][];
        for (int i = 0; i < tileCount; i++)
        {
            kinds[i] = new TileKind[tileCount];
            dirs[i] = new DirKind[tileCount];
            heights[i] = new HeightLevel[tileCount];
            tiles[i] = new Tile[tileCount];
            vals[i] = new int[tileCount];
            corners[i] = new int[tileCount];
        }
    }
    public void Generate(int seed)
    {
        Random.InitState(seed);
        int toVal = -1;
        for (int x = 0; x < tileCount; x++)
        {
            for (int z = 0; z < tileCount; z++)
            {
                vals[x][z] = toVal;
                corners[x][z] = -1;
            }
        }
        int maxW;
        int minW;
        int w;
        int minH;
        int maxH;
        int h;
        Vector2Int borderA = new Vector2Int(-4, tileCount * 2);
        Vector2Int borderB = new Vector2Int(-4, tileCount * 2 );
        for (int i = 0; i < 9; i++)
        {

            maxW = tileCount / 2;
            minW = 1;// tileCount / 8;
            w = Random.Range(minW, maxW);
            minH = 1;
            maxH = tileCount / 12;
            h = Random.Range(minH, maxH);
            Scan(HeightLevel.Three, w, h, borderA, borderB);
        }
        borderA = new Vector2Int(-6, tileCount);
        //if (false)
        for (int i = 0; i < 6; i++)
        {
            maxW = tileCount / 2;
            minW = 1;// tileCount / 8;
            minH = 1;
            maxH = tileCount / 8;
            w = Random.Range(minW, maxW);
            h = Random.Range(minH, maxH);
            Scan(HeightLevel.Two, w, h, borderA, borderB);
        }
        borderA = new Vector2Int(0, tileCount);
        borderA = new Vector2Int(0, tileCount);
        //if (false)
        for (int i = 0; i < 16; i++)
        {
            maxW = tileCount / 4;
            minW = 1;// tileCount / 18;
            minH = 1;
            maxH = tileCount / 6;
            w = Random.Range(minW, maxW);
            h = Random.Range(minH, maxH);
            Scan(HeightLevel.One, w, h, borderA, borderB);
        }
        for (int i = 0; i < 128; i++)
        {
            maxW = 7;
            minW = 1;// tileCount / 18;
            minH = 1;
            maxH = 3;
            w = Random.Range(minW, maxW);
            h = Random.Range(minH, maxH);
            Scan(HeightLevel.One, w, h, borderA, borderB);
        }

        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[z][x];
                if (TileKind.Flat == kind)
                {
                    HeightLevel level = heights[z][x];
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
                    tiles[z][x] = tile;
                }
            }
        }
        //FillGap(HeightLevel.Four);
        FillGap(HeightLevel.Three);
        FillGap(HeightLevel.Two);
        FillGap(HeightLevel.One);

        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[z][x];
                DirKind dir = dirs[z][x];
                if (TileKind.Ramp == kind)
                {
                    HeightLevel level = heights[z][x];
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
                    tiles[z][x] = tile;
                }
            }
        }
        //
        FillCorner();
        ExtendRampByLevel(HeightLevel.One);
        ExtendRampByLevel(HeightLevel.Zero);

        FillGround();
    }
    void FillGround()
    {
        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                if (TileKind.None == kinds[z][x])
                {
                    TileKind kind = TileKind.Flat;
                     GameObject tmp = SimpleGenerator.Instance.tiles[kind];
                    GameObject go = GameObject.Instantiate<GameObject>(tmp);
                    Tile tile = go.GetComponent<Tile>();
                    tile.heightLev = HeightLevel.Zero;
                    tile.kind = kind;
                    go.SetActive(true);
                    Transform tr = go.transform;
                    tr.position = new Vector3(x, 0, z);
                    tr.rotation = Quaternion.identity;
                    tiles[z][x] = tile;
                }
            }
        }
    }
    void ExtendRampByLevel(HeightLevel ofLevel)
    {
        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[z][x];
                DirKind dir = dirs[z][x];
                HeightLevel level = heights[z][x];
                if (level != ofLevel) continue;
                Tile tile = tiles[z][x];
                Vector2Int coord = new Vector2Int(z, x);
                if (kind == TileKind.Ramp)
                {
                    if (z - 1 >= 0)
                    {
                        if (kinds[z - 1][x] == TileKind.None)
                        {
                            ExtendRamp(coord, new Vector2Int(-1, 0), tile);
                        }
                    }
                    if (z + 1 < tileCount)
                    {
                        if (kinds[z + 1][x] == TileKind.None)
                        {
                            ExtendRamp(coord, new Vector2Int(1, 0), tile);
                        }
                    }
                    if (x - 1 >= 0)
                    {
                        if (kinds[z][x - 1] == TileKind.None)
                        {
                            ExtendRamp(coord, new Vector2Int(0, -1), tile);
                        }
                    }
                    if (x + 1 < tileCount)
                    {
                        if (kinds[z][x + 1] == TileKind.None)
                        {
                            ExtendRamp(coord, new Vector2Int(0, 1), tile);
                        }
                    }
                }
            }
        }
    }
    void ExtendRamp(Vector2Int coord0, Vector2Int dir, Tile tile)
    {
        Vector3 fwd = tile.transform.forward;
        Vector3 xdir = new Vector3(dir.y, 0, dir.x);
        if (Vector3.Dot(fwd, xdir) > 0.8f) { return; }

        Vector2Int coord;
        int atX, atZ;
        bool canSeam = false;
        int toK = 0;
        for (int k = 1; k < 64; k++)
        {
            coord = coord0 + dir * k;
            atX = coord.x;
            atZ = coord.y;//数组坐标
            if (atX < 0 || atZ < 0 || atX >= tileCount || atZ >= tileCount)
            {
                canSeam = true;
                toK = k - 1;
                break;
            }
            if (kinds[atX][atZ] == TileKind.Corner)
            {
                canSeam = true;
                toK = k;
                break;
            }
        }
        if (!canSeam) return;

        for (int k = 1; k <= toK; k++)
        {
            coord = coord0 + dir * k;
            atX = coord.x;
            atZ = coord.y;//数组坐标
            if (atX < 0 || atZ < 0 || atX >= tileCount || atZ >= tileCount)
            {
                return;
            }
            if (kinds[atX][atZ] == TileKind.None)
            {
                GameObject go = GameObject.Instantiate<GameObject>(tile.gameObject);
                Tile tileX = go.GetComponent<Tile>();
                Transform tr = go.transform;
                float h = tr.position.y;
                tr.position = new Vector3(coord.y, h, coord.x);
                tiles[atX][atZ] = tileX;
                kinds[atX][atZ] = TileKind.Ramp;
            }
            else if (kinds[atX][atZ] == TileKind.Corner)
            {
                break;
            }
        }
    }
    void FillGap(HeightLevel ofLevel)
    {
        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[z][x];
                if (TileKind.Flat == kind)
                {
                    Tile tile = tiles[z][x];
                    tile.Fill(this, ofLevel, new Vector2Int(z, x));//矩阵索引
                }
            }
        }
    }
    void FillCorner()
    {
        Area area = DisplayArea.display.corner;
        int H = 0;
        int cornerK = 0;
        Vector2Int dir = Vector2Int.zero;
        for (int z = 0; z < tileCount; z++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                TileKind kind = kinds[z][x];
                if (kind == TileKind.Flat)
                {
                    H = (int)heights[z][x];
                    if (x - 1 >= 0 && z - 1 >= 0)
                        if (TileKind.Ramp == kinds[z][x - 1] && TileKind.Ramp == kinds[z - 1][x]
                            && TileKind.None == kinds[z - 1][x - 1])
                        {
                            dir = new Vector2Int(-1, -1);
                            cornerK = 0;
                            DoCorner(H, z, x, dir, cornerK, area);
                        }
                    if (x + 1 < tileCount && z - 1 >= 0)
                        if (TileKind.Ramp == kinds[z][x + 1] && TileKind.Ramp == kinds[z - 1][x]
                            && TileKind.None == kinds[z - 1][x + 1])
                        {
                            dir = new Vector2Int(-1, 1);
                            cornerK = 1;
                            DoCorner(H, z, x, dir, cornerK, area);
                        }
                    if (x + 1 < tileCount && z + 1 < tileCount)
                        if (TileKind.Ramp == kinds[z][x + 1] && TileKind.Ramp == kinds[z + 1][x]
                            && TileKind.None == kinds[z + 1][x + 1])
                        {
                            dir = new Vector2Int(1, 1);
                            cornerK = 2;
                            DoCorner(H, z, x, dir, cornerK, area);
                        }
                    if (x - 1 >= 0 && z + 1 < tileCount)
                        if (TileKind.Ramp == kinds[z][x - 1] && TileKind.Ramp == kinds[z + 1][x]
                            && TileKind.None == kinds[z + 1][x - 1])
                        {
                            dir = new Vector2Int(1, -1);
                            cornerK = 3;
                            DoCorner(H, z, x, dir, cornerK, area);
                        }

                }
            }
        }
    }
    void DoCorner(int H, int z, int x, Vector2Int dir, int cornerK, Area area)
    {
        for (int k = 1; k < 64; k++)
        {
            int h = H - k;
            Vector2Int coord = new Vector2Int(z, x) + dir * k;//矩阵坐标
            if (coord.x < 0 || coord.x >= tileCount || coord.y < 0 || coord.y >= tileCount)
            {
                break;
            }
            kinds[coord.x][coord.y] = TileKind.Corner;
            corners[coord.x][coord.y] = cornerK;
            heights[coord.x][coord.y] = (HeightLevel)h;
            area.Add(new Vector2Int(coord.y, coord.x));

            GameObject tmp = SimpleGenerator.Instance.tiles[TileKind.Corner];
            GameObject go = GameObject.Instantiate<GameObject>(tmp);
            Tile tile = go.GetComponent<Tile>();
            tile.kind = TileKind.Corner;
            tile.heightLev = (HeightLevel)h;
            go.SetActive(true);
            Transform tr = go.transform;
            float offset = (int)h * height;
            tr.position = new Vector3(coord.y, offset, coord.x);//矩阵坐标 转 世界坐标
            Vector3 euler = Vector3.zero;
            switch (cornerK)
            {
                case 0:
                    euler = new Vector3(0, 270, 0);
                    break;
                case 1:
                    euler = new Vector3(0, 180, 0);
                    break;
                case 2:
                    euler = new Vector3(0, 90, 0);
                    break;
                case 3:
                    euler = new Vector3(0, 0, 0);
                    break;
            }
            tr.eulerAngles = euler;
            tiles[coord.x][coord.y] = tile;
            if (H - k - 1 < 0)
            {
                break;
            }
        }
    }
    void Scan(HeightLevel level, int w, int h, Vector2Int borderA, Vector2Int borderB)
    {
        Area area = DisplayArea.GetArea();

        //int atX = Random.Range(-4, tileCount * 3 / 4);
        //int atZ = Random.Range(-4, tileCount * 3 / 4);
        int atX = Random.Range(borderA.x, borderA.y);
        int atZ = Random.Range(borderB.x, borderB.y);
        atX = Mathf.Max(0, atX);
        atZ = Mathf.Max(0, atZ);
        int maxZ = Mathf.Min(atZ + h, tileCount);
        int maxX = Mathf.Min(atX + w, tileCount);

        bool isFine = true;
        for (int z = atZ; z < maxZ; z++)
        {
            for (int x = atX; x < maxX; x++)
            {
                if (vals[z][x] == 1)
                {
                    isFine = false;
                    maxZ = maxZ - 1;
                    break;// continue;
                }
            }
        }
        //if(isFine)
        for (int z = atZ; z < maxZ; z++)
        {
            for (int x = atX; x < maxX; x++)
            {
                if (vals[z][x] == 1)
                {
                    Debug.Log("XX:" + (z - atZ) + "  " + (x - atX));
                    break;// continue;
                }
                kinds[z][x] = TileKind.Flat;
                dirs[z][x] = DirKind.None;
                heights[z][x] = level;
                vals[z][x] = 1;

                area.Add(new Vector2Int(x, z));
            }
        }

        int gap = (int)level * 2;
        //邻接区域
        atZ = Mathf.Max(0, atZ - gap);
        atX = Mathf.Max(0, atX - gap);
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
                corners[i][k] = -1;
                Tile tile = tiles[i][k];
                if (tile != null)
                    GameObject.Destroy(tile.gameObject);
            }
        }
    }
}
