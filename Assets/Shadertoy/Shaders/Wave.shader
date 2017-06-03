Shader "Unlit/Wave"
{
	Properties
	{
		_Scale("Scale", Float) = 25
		_Speed("Speed", Float) = 5
		_Frequency("Frequency", Float) = 0.7
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

			float _Scale;
			float _Speed;
			float _Frequency;

			float D(float2 p, float2 o)
			{
				float d = length(p - o);
				if(d < 0.1)
				{
					return d;
				}
				return 95;
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
				float2 uv = i.uv - 0.5;
				uv *= _Scale;
				float2 f = frac(uv);
				uv = floor(uv);
				float t = sqrt(uv.x*uv.x + uv.y*uv.y) * _Frequency + _Time.y * _Speed;
				float o = float2(cos(t), sin(t)) * 0.4 + 0.5;
				float d= D(f, o);
				float3 col = float3(d, d, d);
				return fixed4(d, d, d, 1.0);
			}
			ENDCG
		}
	}
}
