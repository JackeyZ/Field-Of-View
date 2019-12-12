using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthCamera : MonoBehaviour
{
    Camera mCamera;
    public Material depthMat;
    public RenderTexture renderTexture;
    public bool isInit = false;

    // Start is called before the first frame update
    void Start()
    {
        mCamera = gameObject.GetComponent<Camera>();
        //设置Camera的depthTextureMode,使得摄像机能生成深度图。
        if (mCamera)
        {
            mCamera.depthTextureMode = DepthTextureMode.Depth;
        }
        renderTexture = new RenderTexture(FovData.textureWidth, FovData.textureHeight, 16);
        mCamera.targetTexture = renderTexture;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, depthMat);
        isInit = true;
    }
}
