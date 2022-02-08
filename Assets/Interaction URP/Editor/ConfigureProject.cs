using UnityEngine;
using UnityEditor;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace InteractionURP.Editor
{
    public static class ConfigureProject
    {
        /// <summary>
        /// Add all of the necessary configuration elements for the URP elements in the Interaction SDK
        ///
        /// Currently, this consists of the following:
        /// 1. URP Render Feature for stencil masking
        /// 2. URP Render Feature for objects visible in stencil masked areas
        /// 3. Adding 2 new layers: StencilMask and StencilVis
        /// </summary>
        [MenuItem("Assets/Interaction URP/Configure Project")]
        public static void AddRequiredConfigurationElements()
        {
            if (!EditorUtility.DisplayDialog(
                    "Oculus Interaction URP",
                    "This will attempt to add two new layers using layer values 6 & 7, " +
                    "as well as new URP render features for stencil support on those layers. " +
                    "Press OK to proceed.", "OK", "Cancel"))
            {
                return;
            }

            if (!TryFindRendererDataAsset(out var rendererData))
            {
                ShowError(
                    "Unable to determine which ForwardRenderer configuration to upgrade, please follow the manual instructions");
                return;
            }

            UpdateMainLayerMask(rendererData);
            AddStencilMaskFeature(rendererData);
            AddStencilVisFeature(rendererData);
            EditorUtility.SetDirty(rendererData);
            AssetDatabase.SaveAssetIfDirty(rendererData);

            if (!TryFindTagManager(out var tagManager))
            {
                ShowError(
                    "Unable to load tag manager, you must manually redefine layers 6 and 7 to the names Stencil Mask and Stencil Vis");
                return;
            }

            AddLayer(tagManager, 6, "Stencil Mask");
            AddLayer(tagManager, 7, "Stencil Vis");
            tagManager.ApplyModifiedProperties();

            EditorUtility.DisplayDialog(
                "Oculus Interaction URP",
                "Configuration comnplete! You may need to restart for the renderer changes to become visible",
                "OK");
        }

        #region Layer Editing

        private static bool TryFindTagManager(out SerializedObject tagManager)
        {
            var loaded = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset");
            if (loaded.Length != 1)
            {
                tagManager = null;
                return false;
            }

            tagManager = new SerializedObject(loaded[0]);
            return true;
        }

        private static void AddLayer(SerializedObject tagManager, int layer, string layerName)
        {
            var allLayersProp = tagManager.FindProperty("layers");
            var layerProp = allLayersProp.GetArrayElementAtIndex(layer);
            layerProp.stringValue = layerName;
        }

        #endregion

        #region Renderer Modification

        private static bool TryFindRendererDataAsset(out ForwardRendererData data)
        {
            var rendererDataGuids = AssetDatabase.FindAssets("t:ForwardRendererData", new[] { "Assets/" });
            if (rendererDataGuids?.Length != 1)
            {
                data = null;
                return false;
            }

            var path = AssetDatabase.GUIDToAssetPath(rendererDataGuids[0]);
            data = AssetDatabase.LoadAssetAtPath<ForwardRendererData>(path);
            return true;
        }

        private static void UpdateMainLayerMask(ForwardRendererData data)
        {
            var invMask = ~((1 << 6) | (1 << 7));
            data.opaqueLayerMask  = data.opaqueLayerMask & invMask;
        }

        private static void AddStencilMaskFeature(ForwardRendererData data)
        {
            var renderObj = ScriptableObject.CreateInstance<RenderObjects>();
            renderObj.name = "Stencil Mask";
            renderObj.settings.Event = RenderPassEvent.BeforeRenderingOpaques;
            renderObj.settings.filterSettings = new RenderObjects.FilterSettings
            {
                LayerMask = 1 << 6,
                RenderQueueType = RenderQueueType.Opaque
            };
            renderObj.settings.stencilSettings = new StencilStateData
            {
                overrideStencilState = true,
                stencilReference = 5,
                stencilCompareFunction = CompareFunction.Always,
                passOperation = StencilOp.Replace,
                failOperation = StencilOp.Keep,
                zFailOperation = StencilOp.Keep
            };
            data.rendererFeatures.Add(renderObj);
            EditorUtility.SetDirty(data);
            AssetDatabase.AddObjectToAsset(renderObj, data);
        }

        private static void AddStencilVisFeature(ForwardRendererData data)
        {
            var renderObj = ScriptableObject.CreateInstance<RenderObjects>();
            renderObj.name = "Stencil Vis";
            renderObj.settings.Event = RenderPassEvent.BeforeRenderingOpaques;
            renderObj.settings.filterSettings = new RenderObjects.FilterSettings
            {
                LayerMask = 1 << 7,
                RenderQueueType = RenderQueueType.Opaque
            };
            renderObj.settings.stencilSettings = new StencilStateData
            {
                overrideStencilState = true,
                stencilReference = 5,
                stencilCompareFunction = CompareFunction.Equal,
                passOperation = StencilOp.Keep,
                failOperation = StencilOp.Keep,
                zFailOperation = StencilOp.Keep
            };
            data.rendererFeatures.Add(renderObj);
            EditorUtility.SetDirty(data);
            AssetDatabase.AddObjectToAsset(renderObj, data);
        }

        #endregion

        private static void ShowError(string error)
        {
            EditorUtility.DisplayDialog("Oculus Interaction URP Error", error, "OK");
        }
    }
}