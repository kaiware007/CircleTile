Shader "Custom/Circle Tile"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Radius("Radius", Range(0,1)) = 0.5
		_CenterX("Center X", Float) = 0.5
		_CenterY("Center Y", Float) = 0.5
		_MaskColor("Mask Color", Color) = (0,0,0,0)
		_BlurThickness("Blur Thickness", Range(0.0, 1.0)) = 0.01
		_ColorSaturation("Color Saturation", Range(0,1)) = 0.5
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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			fixed _Radius;
			fixed _CenterX;
			fixed _CenterY;
			fixed4 _MaskColor;
			fixed _BlurThickness;
			fixed _ColorSaturation;

			// hue/saturate/value
			float3 hsv2rgb(float3 c)
			{
				float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
				return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
			}


			// Random
			float random(float2 st) {
				return frac(sin(dot(st.xy,
					float2(12.9898, 78.233)))*
					43758.5453123);
			}

			static const float PI = 3.14159265358979323846;

			// 特定の範囲の値を別の特定の範囲に再配置
			float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
			{
				return outputMin + (outputMax - outputMin) * ((value - inputMin) / (inputMax - inputMin));
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{				
				float dis = distance(i.uv.xy, fixed2(_CenterX, _CenterY));

				/// 曲座標変換
				float2 uv_ = i.uv.xy / _ScreenParams.zw;
				float w = (0.5 - (uv_.x)) * (_ScreenParams.z / _ScreenParams.w);
				float h = 0.5 - uv_.y;
				float distanceFromCenter = sin(sqrt(w * w + h * h) * 2 + cos(_Time.y * 0.25)) * 0.25 + sin(_Time.y * 0.1) * 0.5 + 1.0;	// dynamic version
				//float distanceFromCenter = sin(sqrt(w * w + h * h) * 1 );	// stable version
				float angle = remap(atan2(h + cos(_Time.y * 0.1), w - sin(_Time.y * 0.1)), -PI, PI, 0.0, 1.0);	// dynamic version
				//float angle = remap(atan2(h , w), -PI, PI, 0.0, 1.0);	// stable version

				float2 uv = float2(angle, distanceFromCenter);
				
				// 分割
				float divCount = 64.0;
				
				// いろいろな倍率用
				float2 baiUv = uv * divCount;
				float bai = random(floor(baiUv));
				float brightness = (sin(_Time.y * 1.75 * bai) * 0.5 + 0.5);	// マス単位の明るさ

				float3 color = hsv2rgb(float3(bai * 0.4 + _Time.y * 0.05, saturate(sin(bai * _Time.y) * 0.125 + _ColorSaturation), brightness));

				fixed a = _BlurThickness > 0.0 ? ((dis - (_Radius - _BlurThickness)) / _BlurThickness) : 1;

				color = (dis < (_Radius - _BlurThickness)) ? color : (dis < _Radius) ? lerp(color, _MaskColor.rgb, _MaskColor.a * a) : lerp(color, _MaskColor.rgb, _MaskColor.a);

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}
}
