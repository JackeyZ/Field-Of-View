using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainCameraFov : MonoBehaviour
{
    public DepthCamera depthCamera;
    public Camera mainCamera;
    public GameObject mainRole;
    public GameObject map;

    Material SDFMat;
    public RenderTexture SDFRenderTexture = null;
    bool SDFIsGenerate = false;
    bool SDFIsGenerated = false;                            // SDF是否生成完毕

    Material ShadowMat;
    public RenderTexture shadowRenderTexture = null;
    bool ShadowIsGenerate = false;

    Material BlurMat;
    // Shading parameter
    public int m_BlurInteration = 2;
    public float m_BlurLevel = 8f;
    public float m_BlurResolutionScale = 0.9f;

    Material mainCameraFovMat;

    Matrix4x4 mapTransform = Matrix4x4.zero;
    // Start is called before the first frame update
    void Start()
    {
        mainCamera = GetComponent<Camera>();
        //设置Camera的depthTextureMode,使得摄像机能生成深度图。
        if (mainCamera)
        {
            mainCamera.depthTextureMode = DepthTextureMode.Depth;
        }

        // 生成SDF的材质球
        if (SDFMat == null)
            SDFMat = new Material(Shader.Find("Hidden/FovJumpFloodSDF"));

        if (SDFRenderTexture == null)
        {
            SDFRenderTexture = new RenderTexture(FovData.textureWidth, FovData.textureHeight, 0, RenderTextureFormat.ARGBFloat);
            SDFRenderTexture.wrapMode = TextureWrapMode.Clamp;
            SDFRenderTexture.filterMode = FilterMode.Bilinear;
        }

        // 生成阴影的材质球
        if (ShadowMat == null)
            ShadowMat = new Material(Shader.Find("Hidden/FovShadowSDF"));
        if (shadowRenderTexture == null)
        {
            shadowRenderTexture = new RenderTexture(FovData.textureWidth, FovData.textureHeight, 0, RenderTextureFormat.ARGBFloat);
            shadowRenderTexture.wrapMode = TextureWrapMode.Clamp;
            shadowRenderTexture.filterMode = FilterMode.Bilinear;
        }


        if (BlurMat == null)
            BlurMat = new Material(Shader.Find("Hidden/FovBlurSDF"));

        if (mainCameraFovMat == null)
            mainCameraFovMat = new Material(Shader.Find("Hidden/FovMainCamera")); //FOWEffect

        // 角色的世界坐标转换成角色在地图中的本地坐标
        mapTransform.SetTRS(map.transform.position - new Vector3(FovData.MapWidth / 2, 0, FovData.MapHeight / 2), map.transform.rotation, Vector3.one);    // 地图空间转换矩阵， -25是为了把地图原点放在左下角与UV一致

    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (ShadowIsGenerate)
        {
            mainCameraFovMat.SetMatrix("_WorldToMapMatrix", mapTransform.inverse);
            mainCameraFovMat.SetTexture("_ShadowTexture", shadowRenderTexture);
            mainCameraFovMat.SetFloat("_MapToUvScale", FovData.MapWidth);

            //mainCameraFovMat.SetTexture("_CameraColorBuffer", src);
            //mainCameraFovMat.SetTexture("_FOWTexture", shadowRenderTexture);
            //mainCameraFovMat.SetVector("_InvSize", new Vector2(1f / FovData.MapWidth, 1f / FovData.MapWidth));
            //mainCameraFovMat.SetVector("_PositionWS", map.transform.position);
            //mainCameraFovMat.SetMatrix("_InvVP", (mainCamera.projectionMatrix * mainCamera.worldToCameraMatrix).inverse);
            //mainCameraFovMat.SetMatrix("_FOWWorldToLocal", mapTransform.inverse);
            //mainCameraFovMat.SetColor("_FogColor", new Color(0.35f, 0.35f, 0.35f, 0f));

            Graphics.Blit(src, dest, mainCameraFovMat);
        }
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if (!SDFIsGenerate && depthCamera.isInit)
        {
            SDFIsGenerate = true;
            StartCoroutine(DelayGenerateSDFTexure());
        }
    }

    IEnumerator DelayGenerateSDFTexure()
    {
        yield return null;

        RenderTexture rt0 = RenderTexture.GetTemporary(FovData.textureWidth, FovData.textureHeight, 0, RenderTextureFormat.ARGBFloat);
        RenderTexture rt1 = RenderTexture.GetTemporary(FovData.textureWidth, FovData.textureHeight, 0, RenderTextureFormat.ARGBFloat);

        SDFMat.SetTexture("_MapDepthTexture", depthCamera.renderTexture);
        Graphics.Blit(null, rt0, SDFMat, 0);

        RenderTexture[] pingpong = new RenderTexture[2];
        pingpong[0] = rt0;
        pingpong[1] = rt1;

        float power = Mathf.Log(FovData.textureHeight, 2);
        Vector2 singlePixelUvSize = new Vector2(1.0f / FovData.textureWidth, 1.0f / FovData.textureHeight);

        // 跳跃泛洪算法JFA
        int levelCount = (int)power;
        for (int i = 0; i <= levelCount; i++)
        {
            int level = i > power ? (int)power : i;
            int index0 = i % 2;
            int index1 = (i + 1) % 2;

            SDFMat.SetTexture("_SDFTexture", pingpong[index0]);
            SDFMat.SetVector("_TexelSize", singlePixelUvSize);
            SDFMat.SetFloat("_Level", level);
            SDFMat.SetFloat("_Power", power);
            Graphics.Blit(null, pingpong[index1], SDFMat, 1);
        }

        RenderTexture result = null;
        if (levelCount % 2 == 1)
            result = pingpong[0];
        else
            result = pingpong[1];

        RenderTexture temp = RenderTexture.GetTemporary(FovData.textureWidth, FovData.textureHeight, 0, RenderTextureFormat.ARGBFloat);
        SDFMat.SetTexture("_SDFFinalTexture", result);
        Graphics.Blit(null, temp, SDFMat, 2);
        Graphics.CopyTexture(temp, SDFRenderTexture);

        RenderTexture.ReleaseTemporary(rt0);
        RenderTexture.ReleaseTemporary(rt1);

        SDFIsGenerated = true;
    }

    void Update()
    {
        if (SDFIsGenerated)
        {
            var playerPosWS = mainRole.transform.position;
            var playerRadius = 0.8f;
            
            var playerPosLS = mapTransform.inverse.MultiplyPoint(playerPosWS);
            playerPosLS.x /= FovData.MapWidth;
            playerPosLS.z /= FovData.MapHeight;                                                // 把本地坐标转换成（0，1）对应贴图UV
            
            var playerLSNorm = new Vector2(playerPosLS.x, playerPosLS.z);

            ShadowMat.SetVector("_PlayerPos", playerLSNorm);                    // 玩家归一化之后的本地坐标
            ShadowMat.SetFloat("_PlayerRadius", playerRadius);                  // 光照半径

            ShadowMat.SetFloat("_CutOff", 0.0001f);
            ShadowMat.SetFloat("_Luminance", 3.5f);                             // 亮度
            ShadowMat.SetFloat("_StepScale", 0.9f);
            ShadowMat.SetFloat("_StepMinValue", 0.0001f);

            ShadowMat.SetTexture("_SDFTexture", SDFRenderTexture);
            ShadowMat.SetVector("_TextureSizeScale", Vector2.one);

            Graphics.Blit(null, shadowRenderTexture, ShadowMat);                // 渲染出shadow贴图

            /* 对shadow进行模糊处理 */
            BlurMat.SetVector("_PlayerPos", playerLSNorm);
            BlurMat.SetFloat("_PlayerRadius", playerRadius);

            RenderTexture rt = RenderTexture.GetTemporary(shadowRenderTexture.width, shadowRenderTexture.height, 0);
            Graphics.Blit(shadowRenderTexture, rt);

            BlurMat.SetVector("_TextureTexelSize", Vector2.zero);
            BlurMat.SetFloat("_BlurLevel", m_BlurLevel);
            for (int i = 0; i < m_BlurInteration; i++)
            {
                int width = (int)(m_BlurResolutionScale * rt.width);
                int height = (int)(m_BlurResolutionScale * rt.height);
                var rt2 = RenderTexture.GetTemporary(width, height, 0);
                BlurMat.SetTexture("_FOWTexture", rt);
                Graphics.Blit(null, rt2, BlurMat);

                RenderTexture.ReleaseTemporary(rt);
                rt = rt2;
            }

            Graphics.Blit(rt, shadowRenderTexture);
            RenderTexture.ReleaseTemporary(rt);

            //return shadowRenderTexture;
            ShadowIsGenerate = true;
        }

        //m_BlurMaterial.SetVector("_PlayerPos", playerLSNorm);
        //m_BlurMaterial.SetFloat("_PlayerRadius", playerRadius);
    }
}
