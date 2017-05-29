Shader "Unlit/Specular"
{
	Properties
	{
		_Color ("Tint", Color) = (1.0,1.0,1.0,1.0)

		_MainTex ("Base Color (RGB) Gloss (A)", 2D) = "white" {}
		
		_BumpScale("Bump Scale", Range(-2.0, 2.0)) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		
		_RimMultiplier ("Rim Multiplier", Range(0.0,8.0)) = 0.0
		_RimColor ("Rim Color (RGB) Strength (A)", Color) = (1.0,1.0,1.0,1.0)
		_RimPower ("Rim Power", Range(0.0,16.0)) = 5.0

		_EmissionMultiplier("Emission Multiplier", Float) = 0.0
		_EmissionColor("Emission Color", Color) = (0.0,0.0,0.0)
		_EmissionMap("Emission", 2D) = "white" {}

		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"

			fixed4		_Color;
		
			sampler2D	_MainTex;
			float4		_MainTex_ST;

			sampler2D	_BumpMap;
			float4      _BumpMap_ST;
			half		_BumpScale;

			fixed4 		_RimColor;
			half 		_RimPower;
			half 		_RimMultiplier;
		
			half		_EmissionMultiplier;
			half4 		_EmissionColor;
			sampler2D	_EmissionMap;
			float4      _EmissionMap_ST;

			fixed4      _Specular;
			float       _Gloss;

			struct v2f
			{				
				fixed2 uv : TEXCOORD0;
				fixed2 uv2 : TEXCOORD1;
				float4 pos : SV_POSITION;	
				float3 viewDir : TEXCOORD3;		
				float3 lightDir : TEXCOORD4; 	
				fixed2 uv3 : TEXCOORD5;			
			}; 
			
			v2f vert ( appdata_full  v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uv3 = TRANSFORM_TEX(v.texcoord, _EmissionMap);

				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);


				fixed3 tangentNormal = UnpackScaleNormal(tex2D(_BumpMap, i.uv2), _BumpScale);

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
			  	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;			  	


				fixed3 diffuse = _LightColor0.rgb * albedo * 
				max(0, dot(tangentNormal, tangentLightDir) * 0.5 + 0.5);

				half rimStrength = 1.0 - max(0.0, dot(tangentViewDir, tangentNormal));
				fixed3 rim = _RimMultiplier * _RimColor.rgb * pow(rimStrength, _RimPower) * _RimColor.a;

				fixed3 emission = tex2D(_EmissionMap, i.uv3).rgb;
				
				emission = emission * _EmissionColor.rgb * _EmissionMultiplier;

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

				return  fixed4(ambient + emission + rim + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
}
