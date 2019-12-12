Shader "Hidden/FovShadowSDF"
{
    Properties {}

	SubShader
	{
		Pass
		{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			// Scene dependent parameter
			float _CutOff;
			float _Luminance;
			float _StepScale;
			float _StepMinValue;
			
			float _PlayerRadius;
		    float2 _PlayerPos;
		    float2 _TextureSizeScale;

		    Texture2D _SDFTexture;
			SamplerState _FOW_Trilinear_Clamp_Sampler;

			struct vertInput
			{
				float4 vertex 	: POSITION;
				fixed2 texCoord : TEXCOORD0;
			};

			struct fragInput
			{
				float4 position : SV_POSITION;
				float2 texCoord : TEXCOORD0;
			};

			fragInput vert(vertInput input)
			{
				fragInput output;

                output.texCoord = input.texCoord;
				output.position = UnityObjectToClipPos(input.vertex);

				return output;
			}

			float fillMask(float dist)
			{
				return clamp(-dist, 0.0, 1.0);
			}
			float luminance(float4 col)
			{
				return 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;
			}

			void setLuminance(inout float4 col, float lum)
			{
				lum /= luminance(col);
				col *= lum;
			}


            float drawShadow(float2 uv, float2 lightPos)
			{
			    float2 direction = normalize(lightPos - uv);	// 从像素点指向主角的方向
				float2 p = uv;
			 	float distanceToLight = length(uv - lightPos);
			    float distance = 0.0f;
			    
			    for(int i = 0; i < 32; i++)
			    {
			    	float s = _SDFTexture.Sample(_FOW_Trilinear_Clamp_Sampler, p).r;	// 取得当前像素点离最近障碍物的距离

					//if(i == 0 && s <= 0.00001)
					//{
					//	return 0.5;
					//}

			        if(s <= 0.00001) return 0.0;	// 表示撞墙了
			        
			        if(distance > distanceToLight)	// 表示已找到主角
			            return 1.0;
			        
			        distance += max(s * _StepScale, _StepMinValue);
			        p = uv + direction * distance;
			    }
			    
			    return 0.0;
			}

			float4 drawLight(float2 uv, float2 lightPos, float4 lightColor, float lightRadius)
			{
				// distance to light
				float distanceToLight = length((uv - lightPos) * _TextureSizeScale);
				
				// out of range
				if (distanceToLight > lightRadius) 
					return float4(0.0f, 0.0f, 0.0f, 0.0f);
				
			    float shadow = drawShadow(uv, lightPos);
			    
				float fall = (lightRadius - distanceToLight) / lightRadius;
				fall *= fall;
				return (shadow * fall) * lightColor;
			}

			float4 frag(fragInput input) : SV_TARGET
			{
                float2 uv = input.texCoord;
                // float minLightDistance = tex2D(_SDFTexture, uv);
			    float minLightDistance = _SDFTexture.Sample(_FOW_Trilinear_Clamp_Sampler, uv).r;
			    // float4 value = _SDFTexture.Sample(_FOW_Trilinear_Clamp_Sampler, uv);
			    // return float4(length(uv - value.zw).xxx, 1.0f);
			    // return float4(minLightDistance.xxx, 1.0f);

                float4 lightColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
				setLuminance(lightColor, _Luminance);

                float4 color = float4(0.0f, 0.0f, 0.0f, 1.0f);
				color += drawLight(uv, _PlayerPos, lightColor, _PlayerRadius);
				color = lerp(color, float4(1.0, 0.4, 0.0, 1.0), fillMask(minLightDistance));

                return color;
			}

			ENDCG
		}
	}
}