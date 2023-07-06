using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Generator : MonoBehaviour
{
    const float size = 1f;
    const float size_h = 0.5f;
    const int tileCount = 64;

    public int seed = 0;
    public bool generate = false;
    public PartConfig config;
    Map map;

    // Start is called before the first frame update
    void Start()
    {
        int count = config.parts.Count;
        List<PartProto> protos = new List<PartProto>(6);
        //收集变体信息
        for(int i = 0; i < count; i++)
        {
            GameObject go = config.parts[i];
            PartProto proto = go.GetComponent<PartProto>();
            GlobalVariants.AddVariants(proto.type, proto.variantInfos);
            protos.Add(proto);
        }
        GlobalVariants.Init();
        //收集变体的实例
        for(int i = 0; i < protos.Count; i++)
        {
            protos[i].GetPartVariants();
        }
        map = new Map();
        map.Init(tileCount);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
