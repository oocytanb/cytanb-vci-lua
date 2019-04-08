/*
 * Copyright (c) 2019 oO (https://github.com/oocytanb)
 * MIT Licensed
 */

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using UniGLTF;
using VRM;

namespace cytanb
{
    public static class CytanbBindVrmComponentsMenu
    {
        const string MENU_ITEM_KEY = "Cytanb/Bind VRM Components";

        [MenuItem(MENU_ITEM_KEY, true)]
        static bool ValidatBindVrmComponentsMenu()
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
        static void BindVrmComponentsMenu()
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

                var prefab = ResolvePrefab(root.name);
                if (!prefab)
                {
                    var msg = "[Warning] " + prefab.name + ".prefab was not found.";
                    longMsg += msg + "\n";
                }

                var gltf = new glTF();

                // Meta
                VRMMetaObject meta = null;
#if true
                // refer MetaObject of prefab
                if (prefab)
                {
                    var prefabComponent = prefab.GetComponent<VRMMeta>();
                    if (prefabComponent)
                    {
                        meta = prefabComponent.Meta;
                        meta.Thumbnail = ResolveThumbnail(prefabComponent.Meta.Thumbnail, prefab);
                    }
                }
#else
                // generate MetaObject (deprecated)
                meta = ScriptableObject.CreateInstance<VRMMetaObject>();
                meta.name = "Meta";
                meta.ExporterVersion = gltf.extensions.VRM.exporterVersion;
                meta.Title = root.name;
#endif

                var metaComponent = root.GetComponent<VRMMeta>();
                if (metaComponent && metaComponent.Meta)
                {
                    var msg = "[Skip] VRM Meta component already exists.";
                    longMsg += msg + "\n";
                    Debug.Log(msg);
                }
                else
                {
                    if (!metaComponent)
                    {
                        metaComponent = root.AddComponent<VRMMeta>();
                    }

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

                // BlendShape
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

                var blendShapeAvatarComponent = root.GetComponent<VRMBlendShapeProxy>();
                if (blendShapeAvatarComponent && blendShapeAvatarComponent.BlendShapeAvatar)
                {
                    var msg = "[Skip] VRM Blend Shape Proxy component already exists.";
                    longMsg += msg + "\n";
                    Debug.Log(msg);
                }
                else
                {
                    if (!blendShapeAvatarComponent)
                    {
                        blendShapeAvatarComponent = root.AddComponent<VRMBlendShapeProxy>();
                    }

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

                // secondary
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

            if (!string.IsNullOrEmpty(longMsg))
            {
                var assembly = typeof(UnityEditor.EditorWindow).Assembly;
                EditorWindow.GetWindow(assembly.GetType("UnityEditor.ProjectBrowser")).ShowNotification(new GUIContent(longMsg));
            }
        }

        private static GameObject ResolvePrefab(string rootObjectName)
        {
            string prefabSearchName = rootObjectName + "-normalized";
            foreach (var guid in AssetDatabase.FindAssets("t:prefab " + prefabSearchName))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (string.IsNullOrEmpty(path))
                {
                    continue;
                }

                var prefab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (prefab && !string.IsNullOrEmpty(prefab.name) && prefabSearchName.ToLower().Equals(prefab.name.ToLower()))
                {
                    return prefab;
                }
            }
            return null;
        }

        private static Texture2D ResolveThumbnail(Texture2D thumbnail, GameObject prefab)
        {
            if (!thumbnail || string.IsNullOrEmpty(thumbnail.name))
            {
                return thumbnail;
            }

            if (!prefab)
            {
                return thumbnail;
            }

            string prefabPath = AssetDatabase.GetAssetPath(prefab);
            if (string.IsNullOrEmpty(prefabPath))
            {
                return thumbnail;
            }

            string prefabTextureDir = Path.Combine(Path.GetDirectoryName(prefabPath), prefab.name + ".Textures");

            string thumbnailPath = AssetDatabase.GetAssetPath(thumbnail);
            if (string.IsNullOrEmpty(thumbnailPath))
            {
                return thumbnail;
            }

            string thumbnailDir = Path.GetDirectoryName(thumbnailPath);
            string thumbnailFileName = Path.GetFileName(thumbnailPath);
            if (thumbnailDir != prefabTextureDir)
            {
                return thumbnail;
            }

            foreach (var guid in AssetDatabase.FindAssets("t:Texture2D " + thumbnail.name))
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                string dir = Path.GetDirectoryName(path);
                string fileName = Path.GetFileName(path);
                if (string.IsNullOrEmpty(path) || string.IsNullOrEmpty(dir) || path == thumbnailPath || fileName != thumbnailFileName)
                {
                    continue;
                }

                var targetThumbnail = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                if (!targetThumbnail) {
                    continue;
                }
                
                if (targetThumbnail.imageContentsHash.Equals(thumbnail.imageContentsHash) || IsSameFacility(dir, thumbnailDir))
                {
                    // matched
                    return targetThumbnail;
                }
            }

            return thumbnail;
        }

        private static bool IsSameFacility(string dir1, string dir2)
        {
            if (dir1 == dir2)
            {
                return true;
            }

            if (string.IsNullOrEmpty(dir1) || string.IsNullOrEmpty(dir2))
            {
                return false;
            }

            string shortDir, longDir;
            if (dir1.Length < dir2.Length)
            {
                shortDir = dir1;
                longDir = dir2;
            }
            else
            {
                shortDir = dir2;
                longDir = dir1;
            }

            string shortParentDir = Path.GetDirectoryName(shortDir);
            if (string.IsNullOrEmpty(shortParentDir))
            {
                // need parent directory
                return false;
            }

            string longParentDir = Path.GetDirectoryName(longDir);
            if (string.IsNullOrEmpty(longParentDir))
            {
                // need parent directory
                return false;
            }

            return IsSameFacility(shortDir, longParentDir);
        }
    }
}
