using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum HeightLevel
{
    Zero=0,
    One=1,
    Two=2,
    Three=3,
    None=4,
}
public enum DirKind
{
    None=0,
    Left=1,
    Right=2,
    Bottom=3,
    Top=4
}
public class Tile : MonoBehaviour
{
    public TileKind kind;
         
    public HeightLevel heightLev = HeightLevel.Zero;
    public void Fill(SimpleMap map,HeightLevel level,Vector2Int coord)
    {
        if (heightLev != level) return;
        int tileCount = map.tileCount;

        int x = coord.x;
        int z = coord.y;
        int atX = x-1;
       
        int H = (int)level;
        while (atX >= 0)
        {
            TileKind kind = map.kinds[atX][z];
            if (kind != TileKind.None||heightLev==map.heights[atX][z]) break;

            map.kinds[atX][z] = TileKind.Ramp;
            map.dirs[atX][z] = DirKind.Left;

            H = H - 1;
            map.heights[atX][z] = (HeightLevel)H;
            if (H <= 0) break;
            atX -= 1;
        }
        //
        atX = x + 1;
        H = (int)level;
        while (atX < tileCount)
        {
            TileKind kind = map.kinds[atX][z];
            if (kind != TileKind.None||heightLev==map.heights[atX][z]) break;

            map.kinds[atX][z] = TileKind.Ramp;
            map.dirs[atX][z] = DirKind.Right;

            H -= 1;
            map.heights[atX][z] = (HeightLevel)H;
            if (H <= 0) break;
            atX += 1;
        }

        int atZ = z - 1;
        H = (int)level;
        while (atZ >= 0)
        {
            TileKind kind = map.kinds[x][atZ];
            if (kind != TileKind.None||heightLev==map.heights[x][atZ]) break;

            map.kinds[x][atZ] = TileKind.Ramp;
            map.dirs[x][atZ] = DirKind.Bottom;

            H -= 1;
            map.heights[x][atZ] = (HeightLevel)H;
            if (H <= 0) break;
            atZ -= 1;
        }

        atZ = z + 1;
        H = (int)level;
        while (atZ < tileCount)
        {
            TileKind kind = map.kinds[x][atZ];
            if (kind != TileKind.None||heightLev==map.heights[x][atZ]) break;

            map.kinds[x][atZ] = TileKind.Ramp;
            map.dirs[x][atZ] = DirKind.Top;

            H -= 1;
            map.heights[x][atZ] = (HeightLevel)H;
            if (H <= 0) break;
            atZ += 1;
        }
    }

}
