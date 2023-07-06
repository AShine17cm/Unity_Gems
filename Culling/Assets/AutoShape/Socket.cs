using System;
using System.Collections.Generic;
using UnityEngine;

public class Socket : MonoBehaviour
{
    //public List<PartType> slots;//PoseVariant.Normal
    public List<Target> slots;
    //public List<float> probability;
}

[Serializable]
public class Target
{
    public PartType type;
    public List<PoseVariant> poses;
    public List<float> probability;
}
