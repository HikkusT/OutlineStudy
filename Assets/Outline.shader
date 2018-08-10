﻿Shader "Unlit/Outline"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma multi_compile _ROBERTS_CROSS _PREWITT _SOBEL
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

			struct kernel
			{
				float2 bl;
				float2 bc;
				float2 br;
				float2 ml;
				float2 mc;
				float2 mr;
				float2 tl;
				float2 tc;
				float2 tr;
			};

			struct data
			{
				float3 bl;
				float3 bc;
				float3 br;
				float3 ml;
				float3 mc;
				float3 mr;
				float3 tl;
				float3 tc;
				float3 tr;
			};

			half4 _Background;
			half4 _OutlineColor;

			half _ColorSensitivity;
			half _NormalSensitivity;
			half _DepthSensitivity;

			half _Threshold;
			half _InvRange;

			sampler2D _CameraDepthNormalsTexture;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float2 _MainTex_TexelSize;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			float ApplyFilter(data dt)
			{
				float3 gx = float3(0, 0, 0);
				float3 gy = float3(0, 0, 0);

			#ifdef _ROBERTS_CROSS
				gx = dt.tc - dt.mr;
				gy = dt.tr - dt.mc;
			#endif

			#ifdef _PREWITT
				gx = (dt.tl - dt.tr) + (dt.ml - dt.mr) + (dt.bl - dt.br);
				gy = (dt.tl - dt.bl) + (dt.tc - dt.br) + (dt.tr - dt.br);
			#endif

			#ifdef _SOBEL
				gx = (dt.tl - dt.tr) + 2 * (dt.ml - dt.mr) + (dt.bl - dt.br);
				gy = (dt.tl - dt.bl) + 2 * (dt.tc - dt.br) + (dt.tr - dt.br);
			#endif

				return sqrt(dot(gx, gx) + dot(gy, gy));
			}

			float CalculateEdge(kernel uvs)
			{
				half edge = 0;
				data dt;

				dt.bl = tex2D(_MainTex, uvs.bl).rgb;
				dt.bc = tex2D(_MainTex, uvs.bc).rgb;
				dt.br = tex2D(_MainTex, uvs.br).rgb;
				dt.ml = tex2D(_MainTex, uvs.ml).rgb;
				dt.mc = tex2D(_MainTex, uvs.mc).rgb;
				dt.mr = tex2D(_MainTex, uvs.mr).rgb;
				dt.tl = tex2D(_MainTex, uvs.tl).rgb;
				dt.tc = tex2D(_MainTex, uvs.tc).rgb;
				dt.tr = tex2D(_MainTex, uvs.tr).rgb;

				edge = max(edge, ApplyFilter(dt) * _ColorSensitivity);

				float depth_bl, depth_bc, depth_br, 
					  depth_ml, depth_mc, depth_mr, 
					  depth_tl, depth_tc, depth_tr;

				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.bl), depth_bl, dt.bl);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.bc), depth_bc, dt.bc);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.br), depth_br, dt.br);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.ml), depth_ml, dt.ml);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.mc), depth_mc, dt.mc);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.mr), depth_mr, dt.mr);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.tl), depth_tl, dt.tl);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.tc), depth_tc, dt.tc);
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uvs.tr), depth_tr, dt.tr);

				edge = max(edge, ApplyFilter(dt) * _NormalSensitivity);

				dt.bl = float3(depth_bl, 0, 0);
				dt.bc = float3(depth_bc, 0, 0);
				dt.br = float3(depth_br, 0, 0);
				dt.ml = float3(depth_ml, 0, 0);
				dt.mc = float3(depth_mc, 0, 0);
				dt.mr = float3(depth_mr, 0, 0);
				dt.tl = float3(depth_tl, 0, 0);
				dt.tc = float3(depth_tc, 0, 0);
				dt.tr = float3(depth_tr, 0, 0);

				edge = max(edge, ApplyFilter(dt) * _DepthSensitivity);

				return edge;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				kernel k;
				k.bl = i.uv + float2(-_MainTex_TexelSize.x, -_MainTex_TexelSize.y);		//Bottom Left
				k.bc = i.uv + float2(0, -_MainTex_TexelSize.y);							//Bottom Center
				k.br = i.uv + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y);		//Bottom Right
				k.ml = i.uv + float2(-_MainTex_TexelSize.x, 0);							//Middle Left
				k.mc = i.uv + float2(0, 0);												//Middle Center
				k.mr = i.uv + float2(_MainTex_TexelSize.x, 0);							//Middle Right
				k.tl = i.uv + float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y);		//Top Left
				k.tc = i.uv + float2(0, _MainTex_TexelSize.y);							//Top Center
				k.tr = i.uv + float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y);		//Top Right

				half edge = CalculateEdge(k);
				edge = saturate((edge - _Threshold) * _InvRange);

				half3 bg = tex2D(_MainTex, i.uv);
				bg = lerp(bg, _Background.rgb, _Background.a);
				half3 color = lerp(bg, _OutlineColor.rgb, edge);

				return half4(color, 1.);
			}
			ENDCG
		}
	}
}