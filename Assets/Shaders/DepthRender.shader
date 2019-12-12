// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/DepthRender"
{
    Properties
    {
	}
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_depthrender

            #include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;		// 通过Graphics.Blit 传入
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;  
				float4 scrPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;  
				o.pos = UnityObjectToClipPos(v.vertex);  
				o.scrPos = ComputeScreenPos(o.pos);      // 返回[0, W]的值
                return o;
            }
            fixed4 frag (v2f i) : COLOR//SV_Target
            {
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r);
				return float4(depthValue, depthValue, depthValue, 1.0f); 
            }
            ENDCG
        }
    }
}
