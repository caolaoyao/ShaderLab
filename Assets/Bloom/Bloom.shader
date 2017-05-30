Shader "Hidden/Bloom"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Bloom("Bloom (RGB)", 2D) = "black" {}
		_LuminanceThreshold("Luminance Threshold", Float) = 0.5
		_BlurSize("Blur Size", Float) = 1.0
	}
	SubShader
	{
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		float _BlurSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;

		struct v2f2
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0; 
		};

		v2f2 vertExtractBright(appdata_img v)
		{
			v2f2 o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.texcoord;

			return o;
		} 

		fixed luminance(fixed4 color)
		{
			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		fixed4 fragExtractBright(v2f2 i) : SV_Target
		{
			fixed4 c = tex2D(_MainTex, i.uv);
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			return c * val;
		}

		struct v2fBloom
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0; 
		};

		v2fBloom vertBloom(appdata_img v)
		{
			v2fBloom o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv.xy = v.texcoord;
			o.uv.zw = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_TexelSize.y < 0.0)
			{
				o.uv.w = 1.0 - o.uv.w;
			}
			#endif
			return o;
		}

		fixed4 fragBloom(v2fBloom i) : SV_Target
		{
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		}

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0; 
		};  

		v2f vertBlurVertical(appdata_img v)
		{
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

			half2 uv = v.texcoord;

			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

			return o;
		}

		v2f vertBlurHorizontal(appdata_img v)
		{
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

			half2 uv = v.texcoord;

			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

			return o;
		}

		fixed4 fragBlur(v2f i):SV_Target
		{
			float weight[3] = {0.4026, 0.2442, 0.0545};

			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

			for(int it = 1; it < 3; it++)
			{
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}

			return fixed4(sum, 1.0);
		}

		ENDCG

		ZTest Always Cull Off ZWrite Off

		Pass {
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			ENDCG
		}


		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"

			CGPROGRAM
			#pragma vertex vertBlurVertical
			#pragma fragment fragBlur
			ENDCG
		}  

		Pass {
			NAME "GAUSSIAN_BLUR_HORIZONTAL"

			CGPROGRAM
			#pragma vertex vertBlurHorizontal
			#pragma fragment fragBlur
			ENDCG
		}

		Pass {
			CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom 
			ENDCG
		}
	}
}
