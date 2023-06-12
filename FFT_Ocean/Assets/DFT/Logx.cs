using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Math = System.Math;

public class Logx : MonoBehaviour
{
    public string cc = "l";
    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(cc.ToUpper());
        Debug.Log(Math.Log(512,2));
        Debug.Log(Math.Pow(2, 9));
        int k = 512;
        k <<= 1;
        Debug.Log(k);
        k = 512;
        k = k << 1;
        Debug.Log(k);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
