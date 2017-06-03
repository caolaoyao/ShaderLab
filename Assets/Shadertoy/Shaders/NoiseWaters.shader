Shader "Unlit/NoiseWaters"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float length2(float2 p)
			{
    			return dot(p,p);
			}

			float noise(float2 p)
			{
				return frac(sin(frac(sin(p.x) * (43.13311)) + p.y) * 31.0011);
			}

			float worley(float2 p) 
			{
    			//Set our distance to infinity
				float d = 1e30;
    			//For the 9 surrounding grid points
				for (int xo = -1; xo <= 1; ++xo)
				{
					for (int yo = -1; yo <= 1; ++yo) 
					{
            			//Floor our vec2 and add an offset to create our point
						float2 tp = floor(p) + float2(xo, yo);
            			//Calculate the minimum distance for this grid point
            			//Mix in the noise value too!
						d = min(d, length2(p - tp - noise(tp)));
					}
				}
				return 3.0*exp(-4.0*abs(2.5*d - 1.0));
			}

			float fworley(float2 p)
			{
    			//Stack noise layers 
				return sqrt(sqrt(sqrt(
					worley(p*5.0 + 0.05*_Time.y) *
					sqrt(worley(p * 50.0 + 0.12 + -0.1*_Time.y)) *
					sqrt(sqrt(worley(p * -10.0 + 0.03*_Time.y))))));
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv;
    			//Calculate an intensity
    			float t = fworley(uv * _ScreenParams.xy / 1500.0);
    			//Add some gradient
    			t*=exp(-length2(abs(0.7*uv - 1.0)));	
    			//Make it blue!
    			float4 fragColor = float4(t * float3(0.1, 1.1*t, pow(t, 0.5-t)), 1.0);
    			return fragColor;
			}
			ENDCG
		}
	}
}
