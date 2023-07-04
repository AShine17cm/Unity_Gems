using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class _TestMat : MonoBehaviour
{
    public bool doIt = false;
    public int number;
    public string goName;
    public string avatarName;
    public List<string> anims;
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (doIt)
        {
            doIt = false;
            number = Time.frameCount;
            Replace(gameObject);
        }
    }
    void Replace(GameObject go)
    {
        Dictionary<string, Renderer> renderDic = _TestRes.renderDic;
        Dictionary<string, GameObject> fxDic = _TestRes.fxDic;

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
                    if (mr == null || mr2 == null)
                    {
                        ParticleSystemRenderer psr = rd as ParticleSystemRenderer;
                        ParticleSystemRenderer psr2 = xRender as ParticleSystemRenderer;
                        psr.sharedMaterials = psr2.sharedMaterials;
                        psr.mesh = psr2.mesh;
                    }
                    else
                    {
                        mf.sharedMesh = mf2.sharedMesh;
                        mr.sharedMaterials = mr2.sharedMaterials;
                    }
                }
            }

        }
        //go.name = renders[0].name;
        anims.Clear();
        Animator animator = go.GetComponent<Animator>();
        AnimatorStateInfo asi = animator.GetCurrentAnimatorStateInfo(0);
        AnimatorClipInfo[] infos = animator.GetCurrentAnimatorClipInfo(0);
        for (int k = 0; k < infos.Length; k++)
        {
            anims.Add(infos[k].clip.name);
        }
        avatarName = animator.avatar.name;
        if (avatarName.Equals(_TestRes.Instance.wAvatar.name))
            animator.avatar = _TestRes.Instance.wAvatar;
        else
            animator.avatar = _TestRes.Instance.avatar;
        Transform tr = gameObject.transform;
        int c = tr.childCount;
        for (int m = 0; m < c; m++)
        {
            Transform xtr = tr.GetChild(m);
            if ("SkinMeshRoot".Equals(xtr.name))
            {
                string xName = "unknown";
                int cc = xtr.childCount;
                for (int kk = 0; kk < cc; kk++)
                {
                    if (xtr.GetChild(kk).gameObject.activeSelf)
                    {
                        xName = xtr.GetChild(kk).name;
                        break;
                    }
                }

                int first = xName.IndexOf('_');
                if (first > 0)
                {
                    xName = xName.Substring(first + 1);
                    int second = xName.IndexOf('_');
                    if (second > 0)
                    {
                        xName = xName.Substring(second + 1);
                        go.name = xName;
                        goName = xName;
                    }
                }
            }
        }
        //MonoBehaviour[] monos= go.GetComponentsInChildren<MonoBehaviour>();
        //for(int i=0;i<monos.Length;i++)
        //{
        //    Destroy(monos[i]);
        //}
    }
}
