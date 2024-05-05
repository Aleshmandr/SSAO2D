using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class SSAO2D : MonoBehaviour
{
    [Range(0.0f, 1.0f)] [SerializeField] private float intensity = 0.3f;
    [Range(0.0f, 0.1f)] [SerializeField] private float spread = 0.005f;
    [SerializeField] private Vector2 offset = new Vector2(-0.004f, 0.004f);
    [Range(0.0f, 1.0f)] [SerializeField] private float cutoff = 0.1f;

    [Range(0.000001f, 1.0f)] [SerializeField]
    private float threshold = 0.0001f;

    private Material material;
    private bool isInitialized;
    private static readonly int Intensity = Shader.PropertyToID("intensity");
    private static readonly int Spread = Shader.PropertyToID("spread");
    private static readonly int Cutoff = Shader.PropertyToID("cutoff");
    private static readonly int Threshold = Shader.PropertyToID("threshold");
    private static readonly int Offset = Shader.PropertyToID("offset");

    private const string ShaderName = "Fullscreen/SSAO2D";

    private void Start()
    {
        Init();
    }

    private void OnEnable()
    {
        Init();
    }

    private void Init()
    {
        if (!isInitialized)
        {
            return;
        }

        Shader shader = Shader.Find(ShaderName);
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
        material = new Material(shader);
        isInitialized = true;
    }

    private void OnDisable()
    {
        if (material != null)
        {
            DestroyImmediate(material);
        }

        isInitialized = false;
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetFloat(Intensity, intensity);
        material.SetFloat(Spread, spread);
        material.SetFloat(Cutoff, cutoff);
        material.SetFloat(Threshold, threshold);
        material.SetVector(Offset, offset);
        Graphics.Blit(source, destination, material);
    }
}