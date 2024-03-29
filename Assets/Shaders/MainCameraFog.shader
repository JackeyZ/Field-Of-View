﻿Shader "Custom/MainCameraFog" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass{
            CGPROGRAM

            #include "UnityCG.cginc"
            #pragma vertex vert_img
            #pragma fragment frag
			
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
			sampler2D _EyesDepthTexture;
			float4x4 _EyesV;
			float4x4 _EyesVP;
			float _EyesNearZ;
			float _EyesFarZ;

            float4 GetWorldPositionFromDepthValue( float2 uv, float linearDepth ) 
            {
				//_ProjectionParams.y 是近裁剪面
				//_ProjectionParams.z 是远裁剪面
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;

                // unity_CameraProjection._m11 = near / t，其中t是视锥体near平面的高度的一半。
                // 投影矩阵的推导见：http://www.songho.ca/opengl/gl_projectionmatrix.html。
                // 这里求的height和width是坐标点所在的视锥体截面（与摄像机方向垂直）的高和宽，并且
                // 假设相机投影区域的宽高比和屏幕一致。
                float height = 2 * camPosZ / unity_CameraProjection._m11;
                float width = _ScreenParams.x / _ScreenParams.y * height;

                float camPosX = width * uv.x - width / 2;
                float camPosY = height * uv.y - height / 2;
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
                return mul(unity_CameraToWorld, camPos);
            }

            float4 frag( v2f_img o ) : COLOR
            {
				fixed4 mainColor = tex2D(_MainTex, o.uv);
                float rawDepth =  SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, o.uv );
                // 注意：经过投影变换之后的深度和相机空间里的z已经不是线性关系。所以要先将其转换为线性深度。
                // 见：https://developer.nvidia.com/content/depth-precision-visualized
                float linearDepth = Linear01Depth(rawDepth);
                float4 worldPos = GetWorldPositionFromDepthValue( o.uv, linearDepth);

				float4 eyesClipPos = mul(_EyesVP, worldPos);
				float4 eyesViewPos = mul(_EyesV, worldPos);
				float pixedDepth = -eyesViewPos.z/(_EyesFarZ - _EyesNearZ);
				float projectX = eyesClipPos.x/eyesClipPos.w;
				float projectY = eyesClipPos.y/eyesClipPos.w;

				if(pixedDepth > 0 && projectX >= -1 && projectX <= 1 && projectY >= -1 && projectY <= 1){
					float4 scrPos = ComputeScreenPos(eyesClipPos);
					float eyesLinearDepth = tex2D(_EyesDepthTexture, scrPos/scrPos.w).r;
					if(eyesLinearDepth >= pixedDepth){
						return mainColor;
					}
				}
				return mainColor * 0.2f;
            }
            ENDCG
        }
    } 
}