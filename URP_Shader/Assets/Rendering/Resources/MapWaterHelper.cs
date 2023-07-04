using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public partial class MapWaterHelper : MonoBehaviour
{
    [Header("水体可视区域")] public Texture2D waterVisibleArea;

#if UNITY_EDITOR
    public static bool IsVisible(Vector3 pos, bool isFake = true)
    {
        return true;
    }
#endif
}
