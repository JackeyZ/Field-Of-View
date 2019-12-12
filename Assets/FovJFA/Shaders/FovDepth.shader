// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/FovDepth"
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
            #pragma multi_compile_eyesdepth

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

				//float4 uv = UNITY_PROJ_COORD(i.scrPos) / i.scrPos.w;
				//float4 H = float4(uv.x * 2 - 1, uv.y * 2 - 1, depthValue * 2 - 1, 1); //NDC坐标
				//float4 D = mul(_CurrentInverseVP, H);
				//float4 W = D / D.w; //将齐次坐标w分量变1得到世界坐标
				
				//float disDepth = distance(W, _MainRolePos);

				//float dis = distance(i.worldPos, _MainRolePos);
				//if(dis < disDepth){
				//	return half4(1,1,1,0.5);
				//}
				//return half4(0,0,0,0.5);

            }
            ENDCG
        }
    }
}
