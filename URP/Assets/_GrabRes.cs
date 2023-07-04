#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class _GrabRes : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Prepare();
        GameObject.DontDestroyOnLoad(this);
    }

    // Update is called once per frame
    void Update()
    {

    }
    public static Dictionary<string, Renderer> renderDic = new Dictionary<string, Renderer>(1024);
    public static Dictionary<string, GameObject> fxDic = new Dictionary<string, GameObject>(1024);
    void Prepare()
    {
        renderDic.Clear();
        fxDic.Clear();

        string path = "Assets/";
        string[] ids = AssetDatabase.FindAssets("t:prefab", new string[] { path });
        for (int i = 0; i < ids.Length; i++)
        {
            string ofPath = AssetDatabase.GUIDToAssetPath(ids[i]);
            GameObject go = AssetDatabase.LoadAssetAtPath<GameObject>(ofPath);
            if (go == null) continue;

           Renderer[] renders= go.GetComponentsInChildren<Renderer>();
            for(int k=0;k<renders.Length;k++)
            {
                Renderer renderer = renders[k];
                if (renderer == null) continue;
                renderDic.Add(renderer.name, renderer);
            }

            Debug.Log(go.name);
        }
    }

}
#endif
