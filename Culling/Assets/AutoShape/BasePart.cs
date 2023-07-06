using System;
using System.Collections.Generic;
using UnityEngine;

public enum PartDir
{
    X0 = 0,
    X1 = 1,
    Z0 = 2,
    Z1 = 3,
}
public enum PartType
{
    Flat=0,     //0
    High_1=1,   //
    Saddle=2,   //
    High_3=3,
    Ramp=4,
    Steep=5,    //2倍高度
    Max=6
}
public enum PoseVariant
{
    Normal=0,
    Rotate_90=1,
    Rotate_180=2,
    Rotate_270=3,
    Flip_X=4,
    Flip_Z=5,
    Rotate_90_x1=6,  //x-1
    Rotate_90_z1=7,  //z-1
    Max=8,
}

