using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Parttern
{
    static int seed = 0;

    static void Init(int ofSeed)
    {
        seed = ofSeed;
        Random.InitState(seed);
    }
    static int Next(int min,int max)
    {
        return Random.Range(min, max);
    }

}
