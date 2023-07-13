using System;
using System.Collections.Generic;
using UnityEngine;

public class Socket : MonoBehaviour
{
    public List<Target> slots;
    public int previewIdx = -1;
    public int poseIdx = 0;
}

[Serializable]
public class Target
{
    public PartType type;
    public List<PoseVariant> poses;
    public List<float> probability;
    public List<int> offset;            //高度的偏移
}
