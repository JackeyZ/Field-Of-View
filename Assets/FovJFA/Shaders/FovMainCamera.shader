// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/FovMainCamera"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_MainRolePos("MainRolePos", Vector) = (0,0,0,0)
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" "RenderType" = "Transparent"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_maincamerafog

            #include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;		// 通过Graphics.Blit 传入
			sampler2D _ShadowTexture;
			float _MapToUvScale;
			float4x4 _WorldToMapMatrix;		


            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;  
                float4 uv : TEXCOORD0;
				float4 scrPos : TEXCOORD1;
				float4 worldPos : TEXCOORD10;
            };

			
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

            fixed4 frag ( v2f_img o ) : SV_Target
            {
				fixed4 mianColor = tex2D(_MainTex, o.uv);
                float rawDepth =  SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, o.uv );
                // 注意：经过投影变换之后的深度和相机空间里的z已经不是线性关系。所以要先将其转换为线性深度。
                // 见：https://developer.nvidia.com/content/depth-precision-visualized
                float linearDepth = Linear01Depth(rawDepth);
                float4 worldPos = GetWorldPositionFromDepthValue( o.uv, linearDepth );

				float4 mapLocalPos = mul(_WorldToMapMatrix, worldPos);
				float2 uv = {mapLocalPos.x / _MapToUvScale, mapLocalPos.z / _MapToUvScale};

				fixed4 shadowColor = clamp(tex2D(_ShadowTexture, uv), 0.3f, 1);
				return mianColor * shadowColor;
            }
            ENDCG
        }
    }
}
