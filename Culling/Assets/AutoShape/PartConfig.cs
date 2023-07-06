using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CreateAssetMenu(menuName = "PartConfig")]
public class PartConfig : ScriptableObject
{

    public List<Socket> sockets;
}
