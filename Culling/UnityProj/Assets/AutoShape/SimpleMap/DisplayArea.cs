using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DisplayArea : MonoBehaviour
{
    public List<Color> tints;
    List<Area> areas = new List<Area>(16);
    public Area corner = new Area();
    
   public  static  DisplayArea display;
    static int idx = 0;
    void Start()
    {
        display = this;
        corner.tint = Color.white;
    }
    void Update()
    {
        
    }
    private void OnDrawGizmos()
    {
        for(int i = 0; i < areas.Count; i++)
        {
            areas[i].Draw();
        }
        corner.Draw();
        Gizmos.DrawWireCube(new Vector3(16-0.5f,0,16-0.5f), new Vector3(32, 0, 32));
    }
    public static void AddArea(Area area)
    {
        display.areas.Add(area);
    }
    public static void Clear()
    {
        display.corner.Clear();
        display.areas.Clear();
    }
    public static Area GetArea()
    {
        Area area = new Area();
        idx = (idx + 1) % display.tints.Count;
        area.tint = display.tints[idx];
        display.areas.Add(area);
        return area;
    }
    
}
public class Area
{
    public Color tint;
    List<Vector2Int> points = new List<Vector2Int>();
    public Area()
    {

    }
    public void Clear()
    {
        points.Clear();
    }
    public void Add(Vector2Int coord)
    {
        points.Add(coord);
    }
    public void Draw()
    {
        Vector3 size = new Vector3(1, 0, 1);
        Gizmos.color = tint;
        for(int i = 0; i < points.Count; i++)
        {
            Vector2Int coord = points[i];
            Gizmos.DrawWireCube(new Vector3(coord.x, 0, coord.y), size);
        }
    }
}
