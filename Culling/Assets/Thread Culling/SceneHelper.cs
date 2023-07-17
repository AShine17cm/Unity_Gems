using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneHelper
{
    //查找场景中的 Render
    public static void Collect(List<GameObject> goes)
    {
        goes.Clear();
        Scene scene = SceneManager.GetActiveScene();
        scene.GetRootGameObjects(goes);
        int count = goes.Count;
        for (int i = count - 1; i >= 0; i -= 1)
        {
            GameObject go = goes[i];
            //if (!go.activeSelf) continue;

            MeshRenderer mr = go.GetComponentInChildren<MeshRenderer>();
            if (null == mr)
            {
                goes.RemoveAt(i);
            }
        }
    }


}
