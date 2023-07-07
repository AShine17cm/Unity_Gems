using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleGenerator : MonoBehaviour
{
    public SimpleConfig config;
    public static SimpleGenerator Instance;
    public Dictionary<TileKind, GameObject> tiles = new Dictionary<TileKind, GameObject>(32);
    SimpleMap map;
    public bool generate = false;
    int tileCount = 32;
    //public int seed = 0;
    void Start()
    {
        Instance = this;
        for (int i = 0; i < config.parts.Count; i++)
        {
            Tile tile = config.parts[i].GetComponent<Tile>();
            GameObject go = GameObject.Instantiate<GameObject>(tile.gameObject);
            go.SetActive(false);
            tiles.Add(tile.kind, go);
        }
        map = new SimpleMap(tileCount);
    }

    // Update is called once per frame
    void Update()
    {
        if (generate)
        {
            generate = false;
            DisplayArea.Clear();
            map.Clear();
            int seed = Time.frameCount;
            map.Generate(seed);
        }
    }
}
