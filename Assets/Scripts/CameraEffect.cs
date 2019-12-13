using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraEffect : MonoBehaviour
{
    public Material mainCameraMat;
    public ShieldCameraCtrl[] eyesCamArray;
    public GameObject mainRole;

    // debug
    public RenderTexture shadowMap;

    Camera mCamera;

    void Start()
    {
        mCamera = GetComponent<Camera>();
        //设置Camera的depthTextureMode,使得摄像机能生成深度图。
        if (mCamera)
        {
            mCamera.depthTextureMode = DepthTextureMode.Depth;
        }
        SetTexture();
    }

    void SetTexture()
    {
        mainCameraMat.SetTexture("_EyesDepthTexture0", eyesCamArray[0].renderTexture);
        mainCameraMat.SetTexture("_EyesDepthTexture1", eyesCamArray[1].renderTexture);
        mainCameraMat.SetTexture("_EyesDepthTexture2", eyesCamArray[2].renderTexture);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        RenderTexture rt1 = RenderTexture.GetTemporary(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
        Graphics.Blit(null, rt1, mainCameraMat, 0);
        mainCameraMat.SetTexture("_ShadowMap", rt1);
        Graphics.Blit(src, dest, mainCameraMat, 1);
        shadowMap = rt1;
        RenderTexture.ReleaseTemporary(rt1);
    }

    void Update()
    {
        Matrix4x4[] VArray = new Matrix4x4[eyesCamArray.Length];
        Matrix4x4[] VPArray = new Matrix4x4[eyesCamArray.Length];
        float[] near = new float[eyesCamArray.Length];
        float[] far = new float[eyesCamArray.Length];
        for (int i = 0; i < VArray.Length; i++)
        {
            VArray[i] = eyesCamArray[i].mCamera.worldToCameraMatrix;
            VPArray[i] = eyesCamArray[i].mCamera.projectionMatrix * VArray[i];
            near[i] = eyesCamArray[i].mCamera.nearClipPlane;
            far[i] = eyesCamArray[i].mCamera.farClipPlane;
        }
        mainCameraMat.SetFloatArray("_EyesNearZArray", near);
        mainCameraMat.SetFloatArray("_EyesFarZArray", far);
        mainCameraMat.SetMatrixArray("_EyesVArray", VArray);
        mainCameraMat.SetMatrixArray("_EyesVPArray", VPArray);

        mainCameraMat.SetVector("_RolePos", mainRole.transform.position);

        SetTexture();
    }
}
