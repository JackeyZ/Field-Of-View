Shader "Custom/MainCameraFog2" {
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
			sampler2D _EyesDepthTexture0;		// 视野深度图0
			sampler2D _EyesDepthTexture1;		// 视野深度图1
			sampler2D _EyesDepthTexture2;		// 视野深度图2
			float4x4 _EyesVArray[3];
			float4x4 _EyesVPArray[3];
			float _EyesNearZArray[3];
			float _EyesFarZArray[3];

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
				
				float4 eyesClipPos;
				float pixedDepth = 0;
				int camIndex = 0; 
				for(camIndex = 0; camIndex < 3; camIndex++){
					eyesClipPos = mul(_EyesVPArray[camIndex], worldPos);
					float4 eyesViewPos = mul(_EyesVArray[camIndex], worldPos);
					pixedDepth = -eyesViewPos.z/(_EyesFarZArray[camIndex] - _EyesNearZArray[camIndex]);
					float projectX = eyesClipPos.x/eyesClipPos.w;
					float projectY = eyesClipPos.y/eyesClipPos.w;
					 //是否在视野内
					if(pixedDepth > 0 && projectX >= -1 && projectX <= 1 && projectY >= -1 && projectY <= 1){
						break;
					}
				}

				float4 scrPos = ComputeScreenPos(eyesClipPos);
				float eyesLinearDepth = 1;
				if(camIndex == 0)
				{
					eyesLinearDepth = tex2D(_EyesDepthTexture0, scrPos/scrPos.w).r;
				}
				else if(camIndex == 1)
				{
					eyesLinearDepth = tex2D(_EyesDepthTexture1, scrPos/scrPos.w).r;
				}
				else if(camIndex == 2)
				{
					eyesLinearDepth = tex2D(_EyesDepthTexture2, scrPos/scrPos.w).r;
				}

				if(eyesLinearDepth + 0.002f >= pixedDepth){
					return mainColor;
				}

				return mainColor * 0.2f;
				return float4(0, 0, 0, 1);






				//float4 eyesClipPos = mul(_EyesVP, worldpos);
				//float4 eyesViewPos = mul(_EyesV, worldpos);
				//float objDepth = -eyesViewPos.z/(_EyesFarZ - _EyesNearZ);
				//float projectX = eyesClipPos.x/eyesClipPos.w;
				//float projectY = eyesClipPos.y/eyesClipPos.w;



				////判断是否在视野内
				//if(objDepth > 0 && projectX >= -1 && projectX <= 1 && projectY >= -1 && projectY <= 1){
				//	float4 scrPos = ComputeScreenPos(eyesClipPos);
				//	float eyesLinearDepth = tex2D(_EyesDepthTexture, scrPos/scrPos.w).r;
				//	if(eyesLinearDepth + 0.002f >= objDepth){
				//		return mainColor;
				//	}
				//}
				//return mainColor * 0.2f;
            }
            ENDCG
        }
    } 
}