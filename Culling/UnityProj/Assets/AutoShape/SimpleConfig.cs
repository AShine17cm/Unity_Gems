using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CreateAssetMenu(menuName = "SimpleConfig")]
public class SimpleConfig : ScriptableObject
{
    public List<GameObject> parts;
    
}
