using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class _GrabAct : MonoBehaviour
{
    public bool doIt = false;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if(doIt)
        {
            doIt = false;
        }
    }
    void Replace(GameObject go)
    {
        Dictionary<string, Renderer> renderDic = _GrabRes.renderDic;
        Dictionary<string, GameObject> fxDic = _GrabRes.fxDic;

        Renderer[] renders = go.GetComponentsInChildren<Renderer>();
        for (int i = 0; i < renders.Length; i++)
        {
            Renderer rd = renders[i];
            if (renderDic.TryGetValue(rd.name, out Renderer xRender))
            {
                SkinnedMeshRenderer skin = rd as SkinnedMeshRenderer;
                if (skin)
                {
                    SkinnedMeshRenderer skin2 = xRender as SkinnedMeshRenderer;
                    skin.sharedMesh = skin2.sharedMesh;
                    skin.sharedMaterials = skin2.sharedMaterials;
                }
                else
                {
                    MeshRenderer mr = rd as MeshRenderer;
                    MeshRenderer mr2 = xRender as MeshRenderer;
                    MeshFilter mf = rd.gameObject.GetComponent<MeshFilter>();
                    MeshFilter mf2 = xRender.gameObject.GetComponent<MeshFilter>();
                    mr.sharedMaterials = mr2.sharedMaterials;
                    mf.sharedMesh = mf2.sharedMesh;
                }
            }

        }
    }
}
