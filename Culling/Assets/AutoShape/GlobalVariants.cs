using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlobalVariants 
{
    public const float size = 1f;
    public const float size_h = 0.5f;
    public const float height = 0.5f;
    static int globalId = -1;
    static Dictionary<PartType, Dictionary<PoseVariant, int>> globalTypes = new Dictionary<PartType, Dictionary<PoseVariant, int>>(128);
    static Dictionary<PartType, VariantInfo[]> variantSymmetric = new Dictionary<PartType, VariantInfo[]>(4);
    static Dictionary<int, Part> variants = new Dictionary<int, Part>(128);
    static Dictionary<int, GameObject> variantGoes = new Dictionary<int, GameObject>(128);

    //先收集 变体的对称信息
    public static void AddVariants(PartType partType,VariantInfo[] infos)
    {
        variantSymmetric.Add(partType, infos);
    }
    //ID-s
    public static void Init()
    {
        //基础类型
        for(int i = 0; i < (int)PartType.Max; i++)
        {
            PartType type = (PartType)i;
            Dictionary<PoseVariant, int> poseVariants = new Dictionary<PoseVariant, int>(6);
            globalTypes.Add(type, poseVariants);
            VariantInfo[] sym = variantSymmetric[type];
            //旋转，缩放的变体
            for(int k = 0; k < (int)PoseVariant.Max; k++)
            {
                PoseVariant pose = (PoseVariant)k;
                PoseVariant poseSym = sym[k].symetric;
                if (PoseVariant.Max == poseSym)//无对称
                {
                    globalId += 1;
                    poseVariants.Add(pose, globalId);
                }
                else//有对称,对称在后
                {
                    int sym_id = GetId(type, poseSym);
                    poseVariants.Add(pose, sym_id);
                }
            }
        }
    }
    //返回一个特定变体的id
    public static int GetId(PartType protoType,PoseVariant poseVariant)
    {
      return  globalTypes[protoType][poseVariant];
    }
    public static void AddPart(PartType protoType, PoseVariant poseVariant, Part part)
    {
        int id = globalTypes[protoType][poseVariant];
        variants.Add(id, part);
    }
}
