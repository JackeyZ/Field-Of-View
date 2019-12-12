using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraEffect : MonoBehaviour
{
    public Material mainCameraMat;
    public ShieldCameraCtrl[] eyesCamArray;
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

        float[] near = new float[eyesCamArray.Length];
        float[] far = new float[eyesCamArray.Length];
        for (int i = 0; i < near.Length; i++)
        {
            near[i] = eyesCamArray[i].mCamera.nearClipPlane;
            far[i] = eyesCamArray[i].mCamera.farClipPlane;
        }
        mainCameraMat.SetFloatArray("_EyesNearZArray", near);
        mainCameraMat.SetFloatArray("_EyesFarZArray", far);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, mainCameraMat);
    }

    void Update()
    {
        //Matrix4x4 currentV = eyesCamArray[0].mCamera.worldToCameraMatrix;
        //mainCameraMat.SetMatrix("_EyesV", currentV);
        ////Matrix4x4 currentVP = GL.GetGPUProjectionMatrix(mCamera.projectionMatrix, false) * mCamera.worldToCameraMatrix;
        //Matrix4x4 currentVP = eyesCamArray[0].mCamera.projectionMatrix * currentV;
        //mainCameraMat.SetMatrix("_EyesVP", currentVP);
        //mainCameraMat.SetFloat("_EyesNearZ", eyesCamArray[0].mCamera.nearClipPlane);
        //mainCameraMat.SetFloat("_EyesFarZ", eyesCamArray[0].mCamera.farClipPlane);

        Matrix4x4[] VArray = new Matrix4x4[eyesCamArray.Length];
        Matrix4x4[] VPArray = new Matrix4x4[eyesCamArray.Length];
        for (int i = 0; i < VArray.Length; i++)
        {
            VArray[i] = eyesCamArray[i].mCamera.worldToCameraMatrix;
            VPArray[i] = eyesCamArray[i].mCamera.projectionMatrix * VArray[i];
        }
        mainCameraMat.SetMatrixArray("_EyesVArray", VArray);
        mainCameraMat.SetMatrixArray("_EyesVPArray", VPArray);
    }
}
