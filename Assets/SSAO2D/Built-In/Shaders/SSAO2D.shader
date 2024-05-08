Shader "Hidden/SSAO2D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma exclude_renderers flash
    uniform float4 _MainTex_TexelSize;
    ENDCG

    SubShader
    {
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag


            sampler2D _CameraDepthTexture;
            half intensity;
            half spread;
            half2 offset;
            half cutoff;
            half threshold;

            static const float referenceResolutionScale = 0.001;
            static const fixed2 samples[16] = {
                fixed2(0.0, 1.0),
                fixed2(1.0, 0.0),
                fixed2(0.0, -1.0),
                fixed2(-1.0, 0.0),
                fixed2(0.383, 0.924),
                fixed2(0.707, 0.707),
                fixed2(0.924, 0.383),
                fixed2(0.924, -0.383),
                fixed2(0.707, -0.707),
                fixed2(0.383, -0.924),
                fixed2(-0.383, -0.924),
                fixed2(-0.707, -0.707),
                fixed2(-0.924, -0.383),
                fixed2(-0.924, 0.383),
                fixed2(-0.707, 0.707),
                fixed2(-0.383, 0.924)
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 zuv : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.zuv = o.uv;
                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0.0)
                {
                    o.zuv.y = 1.0 - o.zuv.y;
                }
                #endif
                return o;
            }

            sampler2D _MainTex;


            fixed4 frag(v2f i) : SV_Target
            {
                fixed baseDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.zuv).r);
                float2 aspectCompensation = float2(_ScreenParams.y / _ScreenParams.x, 1.0) * referenceResolutionScale;
                float2 uvOffset = i.uv + offset  * aspectCompensation;

                fixed ambientColor = 1.0;
                offset += i.zuv;
                for (int s = 0; s < 16; s++)
                {
                    float2 sampleOffset = samples[s] * spread * aspectCompensation;
                    fixed diff = baseDepth - LinearEyeDepth(tex2D(_CameraDepthTexture, uvOffset + sampleOffset).r);

                    if (diff > threshold && diff < cutoff)
                    {
                        ambientColor -= (cutoff - clamp(diff, cutoff, threshold)) * intensity;
                    }
                }

                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4(col.r * ambientColor, col.g * ambientColor, col.b * ambientColor, col.a);
            }
            ENDCG
        }
    }
}