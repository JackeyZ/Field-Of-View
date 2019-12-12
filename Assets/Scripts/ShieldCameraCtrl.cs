using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShieldCameraCtrl:MonoBehaviour
{
    public RenderTexture renderTexture;
    public Material mainCameraMat;
    Material eyesCameraMat;

    [HideInInspector]
    public Camera mCamera = null;

    void Awake()
    {
        renderTexture = new RenderTexture(512, 512, 16);
        mCamera = GetComponent<Camera>();
        //设置Camera的depthTextureMode,使得摄像机能生成深度图。
        mCamera.depthTextureMode = DepthTextureMode.Depth;
        mCamera.targetTexture = renderTexture;
    }

    void Start()
    {

        eyesCameraMat = new Material(Shader.Find("Hidden/DepthRender"));
    }

    void OnEnable()
    {
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, eyesCameraMat);
    }
}
