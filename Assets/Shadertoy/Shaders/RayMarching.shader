Shader "Unlit/RayMarching"
{
	Properties
	{
		_MaxMarChingSteps("MaxMarChingSteps", Float) = 255
		_MinDist("MinDist", Float) = 0
		_MaxDist("MaxDist", Float) = 100
		_Epsilon("Epsilon", Float) = 0.0001
	}
	SubShader
	{
		Tags { "LightMode" = "ForwardBase" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float _MaxMarChingSteps;
			float _MinDist;
			float _MaxDist;
			float _Epsilon;

			float sphereSDF(float3 samplePoint)
			{
				return length(samplePoint) - 1.0;
			}

			float sceneSDF(float3 samplePoint)
			{
				return sphereSDF(samplePoint);
			}

			float shortestDistanceToSurface(float3 eye, float3 marchingDirection,
				float start, float end)
			{
				float depth = start;
				for(int i = 0; i < _MaxMarChingSteps; i++)
				{
					float dist = sceneSDF(eye + depth * marchingDirection);
					if(dist < _Epsilon)
					{
						return depth;
					}
					depth += dist;
					if(depth >= end)
					{
						return end;
					}
				}
				return end;
			}

			float3 rayDirection(float fieldOfView, float2 size, float2 fragCoord)
			{
				float2 xy = fragCoord - size / 2.0;
				float z = size.y / tan(radians (fieldOfView) / 2.0);
				return normalize(float3(xy, -z));
			}


			float3 estimateNormal(float3 p)
			{
    			return normalize(float3(
        								sceneSDF(float3(p.x + _Epsilon, p.y, p.z)) - sceneSDF(float3(p.x - _Epsilon, p.y, p.z)),
        								sceneSDF(float3(p.x, p.y + _Epsilon, p.z)) - sceneSDF(float3(p.x, p.y - _Epsilon, p.z)),
        								sceneSDF(float3(p.x, p.y, p.z  + _Epsilon)) - sceneSDF(float3(p.x, p.y, p.z - _Epsilon))
    								));
			}

			float3 phongContribForLight(float3 k_d, float3 k_s, float alpha, float3 p, float3 eye, 
				float3 lightPos, float3 lightIntensity)
			{
				float3 N = estimateNormal(p);
				float3 L = normalize(lightPos - p);
				float3 V = normalize(eye - p);
				float3 R = normalize(reflect(-L, N));

				float dotLN = dot(L, N);
				float dotRV = dot(R,V);
				if(dotLN < 0.0)
				{
					return float3(0, 0, 0);
				}
				if(dotRV < 0.0)
				{
					return lightIntensity * (k_d * dotLN);
				}

				return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
			}

			float3 phongIllumination(float3 k_a, float3 k_d, float3 k_s, float alpha, float3 p, float3 eye)
			{
				float3 ambientLight = 0.5 * float3(1,1,1);
				float3 color = ambientLight * k_a;

				float3 lightPos = float3(4 * sin(_Time.y), 2, 4 * cos(_Time.y));

				float3 lightIntensity = float3(0.4, 0.4, 0.4);

				color += phongContribForLight(k_d, k_s, alpha, p, eye, lightPos, lightIntensity);
    
    			float3 light2Pos = float3(2.0 * sin(0.37 * _Time.y),
                          2.0 * cos(0.37 * _Time.y),
                          2.0);
    			float3 light2Intensity = float3(0.4, 0.4,0.4);
    			color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);    
    			return color;
			}


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0; 
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0; 
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
				float3 dir = rayDirection(45.0, float2(1,1), i.uv);
				float3 eye = float3(0, 0, 5);
				float dist = shortestDistanceToSurface(eye, dir, _MinDist, _MaxDist);

				if(dist > _MaxDist - _Epsilon)
				{
	//				return float4(1, 1, 1, 0);

					discard;
				}

				float3 p = eye + dist * dir;
				float3 k_a = float3(0.2, 0.2, 0.2);
				float3 k_d = float3 (0.7, 0.2, 0.2);
				float3 k_s = float3(1.0, 1.0, 1.0);
				float shininess = 10.0;
				float3 col = phongIllumination(k_a, k_d, k_s, shininess, p, eye);
				return float4(col, 1.0);
			}
			ENDCG
		}
	}
}
