using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(MainCameraFov))]
public class MainCameraFovEditor : Editor
{
    private MainCameraFov m_Target;
    
    void OnEnable()
    {
        m_Target = (MainCameraFov) target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        
        if (m_Target.depthCamera.renderTexture != null)
            GUILayout.Box(m_Target.depthCamera.renderTexture);

        if (m_Target.SDFRenderTexture != null)
            GUILayout.Box(m_Target.SDFRenderTexture);

        if (m_Target.shadowRenderTexture != null)
            GUILayout.Box(m_Target.shadowRenderTexture);
    }
}
