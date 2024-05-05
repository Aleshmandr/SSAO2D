using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSAO2dRendererFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent RenderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public Material Material;
    }

    public Settings settings = new Settings();

    public override void Create()
    {
        pass = new SSAO2DPass(settings.Material, settings.RenderPassEvent);
        name = "SSAO2D Pass";
    }

    private SSAO2DPass pass;

    class SSAO2DPass : ScriptableRenderPass
    {
        private readonly Material material;
        private RenderTargetHandle target;
        private const string radialBlurTargetName = "Radial Blur Target";
        private const string bufferName = "SSAO2D Pass";

        public SSAO2DPass(Material material, RenderPassEvent renderPassEvent)
        {
            this.material = material;
            this.renderPassEvent = renderPassEvent;
            target.Init(radialBlurTargetName);
        }
        
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            cmd.GetTemporaryRT(target.id, renderingData.cameraData.cameraTargetDescriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null)
            {
                Debug.LogError("Material not set.");
                return;
            }

            RenderTargetIdentifier source = renderingData.cameraData.renderer.cameraColorTarget;
            var cmd = CommandBufferPool.Get(bufferName);
            SetShaderParams();
            Blit(cmd, source, target.Identifier(), material);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(target.id);
        }

        private void SetShaderParams()
        {
            //material.SetVector(RadialBlurShaderParams.center, radialBlur.GetCenter());
            //material.SetFloat(RadialBlurShaderParams.intensity, radialBlur.GetIntensity());
            //material.SetFloat(RadialBlurShaderParams.delay, radialBlur.GetDelay());
            //material.SetInt(RadialBlurShaderParams.sampleCount, radialBlur.GetSampleCount());
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
#if UNITY_EDITOR
        if (renderingData.cameraData.camera.cameraType == CameraType.Reflection)
        {
            return;
        }

        if (renderingData.cameraData.camera.cameraType == CameraType.Preview)
        {
            return;
        }

        if (renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            return;
        }
#endif

        renderer.EnqueuePass(pass);
    }
    
    private static class RadialBlurShaderParams
    {
        public static int center = Shader.PropertyToID("_Center");
        public static int intensity = Shader.PropertyToID("_Intensity");
        public static int delay = Shader.PropertyToID("_Delay");
        public static int sampleCount = Shader.PropertyToID("_SampleCount");
    }
}