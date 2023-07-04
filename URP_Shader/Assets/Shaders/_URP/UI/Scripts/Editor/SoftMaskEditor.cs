using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;
using System.Linq;

namespace URP.UISoftMask {
    /// <summary>
    /// SoftMask editor.
    /// </summary>
    [CustomEditor(typeof(SoftMask))]
    [CanEditMultipleObjects]
    public class SoftMaskEditor : UnityEditor.Editor {
        static readonly List<Graphic> s_Graphics = new List<Graphic>();

        public override void OnInspectorGUI() {
            base.OnInspectorGUI();

            var current = target as SoftMask;
            current.GetComponentsInChildren<Graphic>(true, s_Graphics);
            var fixTargets = s_Graphics
                            .Where(x => x.gameObject != current.gameObject)
                            .Where(x => !x.GetComponent<SoftMaskable>() &&
                                        (!x.GetComponent<Mask>() || x.GetComponent<Mask>().showMaskGraphic))
                            .ToList();
            if (0 < fixTargets.Count) {
                GUILayout.BeginHorizontal();
                {
                    EditorGUILayout
                       .HelpBox("There are child Graphics that does not have a SoftMaskable component.\nAdd SoftMaskable component to them.",
                                MessageType.Warning);
                    GUILayout.BeginVertical();
                    {
                        if (GUILayout.Button("Fix")) {
                            foreach (var p in fixTargets) {
                                p.gameObject.AddComponent<SoftMaskable>();
                            }

                            EditorUtils.MarkPrefabDirty();
                        }

                        if (GUILayout.Button("Ping")) {
                            EditorGUIUtility.PingObject(fixTargets[0]);
                        }
                    }
                    GUILayout.EndVertical();
                    GUILayout.EndHorizontal();
                }
            }

            var currentImage = current.graphic as Image;

            if (currentImage && IsMaskUI(currentImage.sprite)) {
                GUILayout.BeginHorizontal();
                {
                    EditorGUILayout
                       .HelpBox("SoftMask does not recommend to use 'UIMask' sprite as a source image.\n(It contains only small alpha pixels.)\nDo you want to use 'UISprite' instead?",
                                MessageType.Warning);
                    GUILayout.BeginVertical();
                    {
                        if (GUILayout.Button("Fix")) {
                            currentImage.sprite = AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/UISprite.psd");
                        }
                    }
                    GUILayout.EndVertical();
                    GUILayout.EndHorizontal();
                }
            }
            
        }

        static bool IsMaskUI(Object obj) {
            return obj
                && obj.name == "UIMask"
                && AssetDatabase.GetAssetPath(obj) == "Resources/unity_builtin_extra";
        }


        //%%%% Context menu for editor %%%%
        [MenuItem("CONTEXT/Mask/Convert To SoftMask", true)]
        private static bool _ConvertToSoftMask(MenuCommand command) {
            return EditorUtils.CanConvertTo<SoftMask>(command.context);
        }

        [MenuItem("CONTEXT/Mask/Convert To SoftMask", false)]
        private static void ConvertToSoftMask(MenuCommand command) {
            EditorUtils.ConvertTo<SoftMask>(command.context);
        }

        [MenuItem("CONTEXT/Mask/Convert To Mask", true)]
        private static bool _ConvertToMask(MenuCommand command) {
            return EditorUtils.CanConvertTo<Mask>(command.context);
        }

        [MenuItem("CONTEXT/Mask/Convert To Mask", false)]
        private static void ConvertToMask(MenuCommand command) {
            EditorUtils.ConvertTo<Mask>(command.context);
        }
    }
}