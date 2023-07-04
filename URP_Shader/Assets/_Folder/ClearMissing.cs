#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class ClearMissing
{
    [MenuItem("Art/清理Missing")]
    //static void ClearCollider()
    //{
    //    const string partFolder = "Assets/_Folder";
    //    string[] tmps = AssetDatabase.FindAssets("t:prefab", new string[] { partFolder });
    //    //加载 基础部件
    //    for (int i = 0; i < tmps.Length; i++)
    //    {
    //        string path = AssetDatabase.GUIDToAssetPath(tmps[i]);
    //        var go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
    //        Collider[] colliders = go.GetComponentsInChildren<Collider>();
  

    //        for (int t = 0; t < colliders.Length; t++)
    //        {
    //            //GameObject.DestroyImmediate(colliders[t]);
    //            colliders[t].gameObject.RemoveComponentIfExist<Collider>();
                
    //        }
    //        if (colliders.Length > 0)
    //        {
    //            PrefabUtility.SavePrefabAsset(go);
    //        }
    //        return;
    //    }
    //    AssetDatabase.Refresh();
    //}
    static void Start()
    {
        const string partFolder = "Assets/_Folder";
        string[] tmps = AssetDatabase.FindAssets("t:prefab", new string[] { partFolder });

        List<Transform> trs = new List<Transform>(128);
        //加载 基础部件
        for (int i = 0; i < tmps.Length; i++)
        {
            trs.Clear();
            int count = 0;
            string path = AssetDatabase.GUIDToAssetPath(tmps[i]);
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
            Transform tmpTr = go.transform;
            AddChild(tmpTr, trs);

            for (int t = 0; t < trs.Count; t++)
            {
                TryClear(trs[t].gameObject, ref count);
            }
            if (count > 0)
            {
                PrefabUtility.SavePrefabAsset(go);
            }
        }
        AssetDatabase.Refresh();
    }
    static void AddChild(Transform tr, List<Transform> set)
    {
        MonoBehaviour[] monos = tr.GetComponents<MonoBehaviour>();
        for (int i = 0; i < monos.Length; i++)
        {
            if (null == monos[i])
            {
                set.Add(tr);
                break;
            }
        }
        for (int k = 0; k < tr.childCount; k++)
        {
            AddChild(tr.GetChild(k), set);
        }
    }
    static void TryClear(GameObject go, ref int count)
    {
        int tmp = GameObjectUtility.RemoveMonoBehavioursWithMissingScript(go);
        count += tmp;
    }
}
#endif
