using UnityEngine;

[DisallowMultipleComponent]
public sealed class StreetlightFlicker : MonoBehaviour
{
    [SerializeField] private Light lamp;
    [SerializeField] private Renderer lens;
    [SerializeField] private Renderer glow;
    [SerializeField] private float phase;

    private static readonly int EmissionColor = Shader.PropertyToID("_EmissionColor");
    private static readonly int GlowStrength = Shader.PropertyToID("_GlowStrength");
    private MaterialPropertyBlock lensProperties;
    private MaterialPropertyBlock glowProperties;
    private Color baseEmission;
    private float baseIntensity;

    private void Awake()
    {
        baseIntensity = lamp.intensity;
        baseEmission = lens.sharedMaterial.GetColor(EmissionColor);
        lensProperties = new MaterialPropertyBlock();
        lens.GetPropertyBlock(lensProperties);
        if (glow != null)
        {
            glowProperties = new MaterialPropertyBlock();
            glow.GetPropertyBlock(glowProperties);
        }
    }

    private void Update()
    {
        float time = Time.time;
        float drift = Mathf.PerlinNoise(phase, time * 2.4f);
        float dip = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(.61f, .85f,
            Mathf.PerlinNoise(phase + 17f, time * 8.3f)));
        float brightness = Mathf.Lerp(.89f, 1.04f, drift) - .23f * dip;
        lamp.intensity = baseIntensity * brightness;
        lensProperties.SetColor(EmissionColor, baseEmission * brightness);
        lens.SetPropertyBlock(lensProperties);
        if (glow != null)
        {
            glowProperties.SetFloat(GlowStrength, brightness);
            glow.SetPropertyBlock(glowProperties);
        }
    }
}
