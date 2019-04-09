﻿Shader "Custom/Toon"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Albedo("Albedo", Color) = (1, 1, 1, 1)
        _RampTex("Ramp Texture", 2D) = "white" {}
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
		_OutlineSize("Outline Size", Range(0.001, 0.1)) = 0.05
		_BumpTex("Normal", 2D) = "bump" {}
		_NormalAmount("Normal Amount", Range(-3, 3)) = 1
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
		_RimPower("Rim Amount", Range(0.5, 8.0)) = 1
    }

    SubShader
    {
        CGPROGRAM
        #pragma surface surf ToonRamp
        
        float4 _Albedo;
        sampler2D _MainTex;
        sampler2D _RampTex;
		sampler2D _BumpTex;
		float _NormalAmount;
		float4 _RimColor;
		float _RimPower;

        float4 LightingToonRamp(SurfaceOutput s, fixed2 lightDir, fixed atten)
        {
            half diff = dot(s.Normal, lightDir);//-1 hasta +1
            float uv = (diff * 0.5) + 0.5;// la cordenada donde voy a ver el UV.
			float3 ramp = tex2D(_RampTex, uv).rgb;
			float4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * ramp;
			c.a = s.Alpha;
			return c;
        }

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_BumpTex;
			float3 viewDir;
		};

		void surf(Input IN, inout SurfaceOutput o)
		{
			o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb * _Albedo.rgb;
			float3 normal = UnpackNormal(tex2D(_BumpTex, IN.uv_BumpTex));
			normal.z = normal.z / _NormalAmount;
			o.Normal = normal;
			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			o.Emission = _RimColor.rgb * pow(rim, _RimPower);
		}

        ENDCG

		Pass
		{
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 color : COLOR;
			};

			float4 _OutlineColor;
			float _OutlineSize;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				float3 norm = normalize(mul ((float3x3)UNITY_MATRIX_IT_MV, 
				v.normal));
                float2 offset = TransformViewToProjection(norm.xy);

				//Tamaño de la linea alrededor del cuerpo y profundidad;
                o.pos.xy += offset * o.pos.z * _OutlineSize;
                o.color = _OutlineColor;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return i.color;
			}

			ENDCG
		}
    }
}
