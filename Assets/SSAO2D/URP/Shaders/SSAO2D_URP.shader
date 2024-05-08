Shader "Fullscreen/SSAO2D"
{
    Properties
    {
        _Spread ("Spread", Vector) = (4, 4, 4, 0) // XY - Offset, Z - Spread
        _Cutoff ("Cutoff", float) = 0.2
        _Threshold ("Threshold", float) = 0.00001
        _Intensity ("Intensity", float) = 0.3
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        ZWrite Off Cull Off
        Pass
        {
            Name "ColorBlitPass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            float4 _Spread;
            float _Intensity;
            float _Cutoff;
            float _Threshold;

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            static const float referenceResolutionScale = 0.001;
            static const float2 samples[16] = {
                float2(0.0, 1.0),
                float2(1.0, 0.0),
                float2(0.0, -1.0),
                float2(-1.0, 0.0),
                float2(0.383, 0.924),
                float2(0.707, 0.707),
                float2(0.924, 0.383),
                float2(0.924, -0.383),
                float2(0.707, -0.707),
                float2(0.383, -0.924),
                float2(-0.383, -0.924),
                float2(-0.707, -0.707),
                float2(-0.924, -0.383),
                float2(-0.924, 0.383),
                float2(-0.707, 0.707),
                float2(-0.383, 0.924)
            };

            struct appdata
            {
                uint vertexID : SV_VertexID;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;

                #if SHADER_API_GLES
                    float4 pos = input.positionOS;
                    float2 uv  = input.uv;
                #else
                float4 pos = GetFullScreenTriangleVertexPosition(v.vertexID);
                float2 uv = GetFullScreenTriangleTexCoord(v.vertexID);
                #endif

                o.vertex = pos;
                o.uv = uv;

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv);
                float baseDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv), _ZBufferParams);
                float2 aspectCompensation = float2(_ScreenParams.y / _ScreenParams.x, 1.0) * referenceResolutionScale;
                float2 uvOffset = i.uv +  _Spread.xy * aspectCompensation;
                float ambientColor = 1.0;
                for (int s = 0; s < 16; s++)
                {
                    float2 sampleOffset =samples[s] * _Spread.z * aspectCompensation;
                    float diff = baseDepth - LinearEyeDepth(
                        SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uvOffset + sampleOffset).r,
                        _ZBufferParams);

                    if (diff > _Threshold && diff < _Cutoff)
                    {
                        ambientColor -= (_Cutoff - clamp(diff, _Cutoff, _Threshold)) * _Intensity;
                    }
                }

                col.rgb *= ambientColor;
                return col;
            }
            ENDHLSL
        }
    }
}