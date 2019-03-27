/*
 * Copyright (c) 2019 oO (https://github.com/oocytanb)
 * MIT Licensed
 */

using System;
using UnityEditor;
using UnityEngine;
using UniGLTF;
using VRM;

namespace cytanb
{
    public static class VRMBindExtComponentsMenu
    {
        const string MENU_ITEM_KEY = VRMVersion.MENU + "/Bind ExtComponents";

        [MenuItem(MENU_ITEM_KEY, true)]
        static bool ValidatBindExtComponentsMenu()
        {
            var root = Selection.activeObject as GameObject;
            if (!root)
            {
                return false;
            }

            var animator = root.GetComponent<Animator>();
            if (!animator)
            {
                return false;
            }

            return true;
        }

        [MenuItem(MENU_ITEM_KEY, false)]
        static void BindExtComponentsMenu()
        {
            var longMsg = "";

            try
            {
                var root = Selection.activeObject as GameObject;
                if (!root)
                {
                    EditorUtility.DisplayDialog("Error", "There is no selected object.", "OK");
                    return;
                }

                GameObject prefab = null;
                var prefabName = root.name + "-normalized";
                foreach (var guid in AssetDatabase.FindAssets("t:prefab " + prefabName))
                {
                    prefab = AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guid));
                    break;
                }

                if (!prefab)
                {
                    var msg = "[Warning] " + prefabName + ".prefab was not found.";
                    longMsg += msg + "\n";
                }

                var gltf = new glTF();

                if (root.GetComponent<VRMMeta>())
                {
                    var msg = "[Skip] VRM Meta component already exists.";
                    longMsg += msg + "\n";
                    Debug.Log(msg);
                }
                else
                {
                    VRMMetaObject meta = null;
#if true
                    // refer MetaObject of prefab
                    if (prefab)
                    {
                        var prefabComponent = prefab.GetComponent<VRMMeta>();
                        if (prefabComponent)
                        {
                            meta = prefabComponent.Meta;
                        }
                    }
#else
                    // generate MetaObject (deprecated)
                    meta = ScriptableObject.CreateInstance<VRMMetaObject>();
                    meta.name = "Meta";
                    meta.ExporterVersion = gltf.extensions.VRM.exporterVersion;
                    meta.Title = root.name;
#endif
                    var metaComponent = root.AddComponent<VRMMeta>();
                    if (meta)
                    {
                        metaComponent.Meta = meta;

                        var msg = "[OK] VRM Meta component was bound.";
                        longMsg += msg + "\n";
                        Debug.Log(msg);
                    }
                    else
                    {
                        var msg = "[Warning] Empty VRM Meta component was created.";
                        longMsg += msg + "\n";
                        Debug.LogWarning(msg);
                    }
                }

                if (root.GetComponent<VRMBlendShapeProxy>())
                {
                    var msg = "[Skip] VRM Blend Shape Proxy component already exists.";
                    longMsg += msg + "\n";
                    Debug.Log(msg);
                }
                else
                {
                    BlendShapeAvatar blendShapeAvatar = null;
#if true
                    // refer BlendShapeAvatar of prefab
                    if (prefab)
                    {
                        var prefabComponent = prefab.GetComponent<VRMBlendShapeProxy>();
                        if (prefabComponent)
                        {
                            blendShapeAvatar = prefabComponent.BlendShapeAvatar;
                        }
                    }
#else
                    // generate BlendShapeAvatar (deprecated)
                    blendShapeAvatar = ScriptableObject.CreateInstance<BlendShapeAvatar>();
                    blendShapeAvatar.name = "BlendShape";
                    blendShapeAvatar.CreateDefaultPreset();

                    foreach (var clip in blendShapeAvatar.Clips)
                    {
                        clip.Prefab = root;
                    }
#endif
                    var blendShapeAvatarComponent = root.AddComponent<VRMBlendShapeProxy>();
                    if (blendShapeAvatar)
                    {
                        blendShapeAvatarComponent.BlendShapeAvatar = blendShapeAvatar;
                        var msg = "[OK] VRM Blend Shape Proxy component was bound.";
                        longMsg += msg + "\n";
                        Debug.Log(msg);
                    }
                    else
                    {
                        var msg = "[Warning] VRM Blend Shape Proxy component was created.";
                        longMsg += msg + "\n";
                        Debug.LogWarning(msg);
                    }
                }

                if (root.transform.Find("secondary"))
                {
                    var msg = "[Skip] secondary object already exists.";
                    longMsg += msg + "\n";
                    Debug.Log(msg);
                }
                else
                {
                    GameObject secondary = null;
                    if (prefab)
                    {
                        var prefabSecondary = prefab.transform.Find("secondary").gameObject;
                        if (prefabSecondary)
                        {
                            secondary = GameObject.Instantiate(prefabSecondary);
                            secondary.transform.SetParent(root.transform, false);
                            secondary.transform.localPosition = prefabSecondary.transform.localPosition;
                            secondary.transform.localScale = prefabSecondary.transform.localScale;
                            secondary.name = "secondary";

                            var msg = "[OK] secondary object was cloned.";
                            longMsg += msg + "\n";
                            Debug.Log(msg);
                        }
                    }

                    if (!secondary)
                    {
                        secondary = new GameObject("secondary");
                        secondary.transform.SetParent(root.transform, false);
                        secondary.AddComponent<VRMSpringBone>();

                        var msg = "[Warning] Empty secondary object was created.";
                        longMsg += msg + "\n";
                        Debug.LogWarning(msg);
                    }
                }
            }
            catch (Exception e)
            {
                longMsg += "Failed to bind components: Unsupported operation.";
                Debug.LogException(e);
            }

            if (!String.IsNullOrEmpty(longMsg))
            {
                var assembly = typeof(UnityEditor.EditorWindow).Assembly;
                EditorWindow.GetWindow(assembly.GetType("UnityEditor.ProjectBrowser")).ShowNotification(new GUIContent(longMsg));
            }
        }
    }
}
