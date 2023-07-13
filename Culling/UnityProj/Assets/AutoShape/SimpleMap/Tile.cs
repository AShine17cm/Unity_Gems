using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum HeightLevel
{
    Zero=0,
    One=1,
    Two=2,
    Three=3,
    //Four=4,
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
    public void Fill(SimpleMap map,HeightLevel level,Vector2Int coord)//此时只有 tile
    {
        if (heightLev != level) return;
        int tileCount = map.tileCount;

        int z = coord.x;//矩阵坐标
        int x = coord.y;
        int atX = x-1;
       
        int H = (int)level;
        while (atX >= 0)
        {
            TileKind kind = map.kinds[z][atX];
            if (kind != TileKind.None||heightLev==map.heights[z][atX]) break;

            map.kinds[z][atX] = TileKind.Ramp;
            map.dirs[z][atX] = DirKind.Left;

            H = H - 1;
            map.heights[z][atX] = (HeightLevel)H;
            if (H <= 0) break;
            atX -= 1;
        }
        //
        atX = x + 1;
        H = (int)level;
        while (atX < tileCount)
        {
            TileKind kind = map.kinds[z][atX];
            if (kind != TileKind.None||heightLev==map.heights[z][atX]) break;

            map.kinds[z][atX] = TileKind.Ramp;
            map.dirs[z][atX] = DirKind.Right;

            H -= 1;
            map.heights[z][atX] = (HeightLevel)H;
            if (H <= 0) break;
            atX += 1;
        }

        int atZ = z - 1;
        H = (int)level;
        while (atZ >= 0)
        {
            TileKind kind = map.kinds[atZ][x];
            if (kind != TileKind.None||heightLev==map.heights[atZ][x]) break;

            map.kinds[atZ][x] = TileKind.Ramp;
            map.dirs[atZ][x] = DirKind.Bottom;

            H -= 1;
            map.heights[atZ][x] = (HeightLevel)H;
            if (H <= 0) break;
            atZ -= 1;
        }

        atZ = z + 1;
        H = (int)level;
        while (atZ < tileCount)
        {
            TileKind kind = map.kinds[atZ][x];
            if (kind != TileKind.None||heightLev==map.heights[atZ][x]) break;

            map.kinds[atZ][x] = TileKind.Ramp;
            map.dirs[atZ][x] = DirKind.Top;

            H -= 1;
            map.heights[atZ][x] = (HeightLevel)H;
            if (H <= 0) break;
            atZ += 1;
        }
    }

}
