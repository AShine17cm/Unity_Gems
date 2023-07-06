using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Socket))]
public class Socket_Editor : Editor
{
    Socket socket;
    PartConfig config;
    Dictionary<PartType, GameObject> dic = new Dictionary<PartType, GameObject>(32);
    GameObject display;
    private void OnEnable()
    {
        socket = target as Socket;
        if (config == null||dic.Count==0)
        {
            string path = "Assets/AutoShape/PartConfig.asset";
            config = AssetDatabase.LoadAssetAtPath<PartConfig>(path);
            if (config == null)
            {
                Debug.LogError("Can not load config");
                return;
            }
            dic.Clear();
            for (int i = 0; i < config.parts.Count; i++)
            {
                GameObject go = config.parts[i];
                PartProto proto = go.GetComponent<PartProto>();
                dic.Add(proto.type, go);
            }
        }
    }
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        GUILayout.Space(10);

        if (GUILayout.Button("Preview Next"))
        {
            int k= socket.previewIdx+1;
            socket.previewIdx = k % socket.slots.Count;
            socket.poseIdx = 0;
            Preview(socket.previewIdx);
        }
        GUILayout.Space(10);
        if (GUILayout.Button("Preview Sub"))
        {
            socket.poseIdx += 1;
            Preview(socket.previewIdx);
        }
    }
    void Preview(int idx)
    {
        if (display != null)
        {
            GameObject.DestroyImmediate(display);
        }
        Target target = socket.slots[idx];
        int k = socket.poseIdx % target.poses.Count;
        socket.poseIdx = k;
        PartType type = target.type;
        PoseVariant pose = target.poses[k];
        int offset = 0;
        if (target.offset != null && target.offset.Count > 0)
        {
            offset = target.offset[k];
        }
        Vector3 offsetH = new Vector3(0, offset, 0) * GlobalVariants.height;
        GameObject go = dic[type];
        display = Instantiate<GameObject>(go);
        Transform tr = display.transform;
        PartProto proto = display.GetComponent<PartProto>();

        Socket[] sockets = proto.SetPose(pose);
        Vector3 posSocket = socket.transform.localPosition;
        posSocket *= 2;
        tr.position = posSocket + offsetH;
        tr.parent = socket.transform;
    }

}
