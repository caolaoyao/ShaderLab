using UnityEngine;
using System.Collections;

public class Bloom : MonoBehaviour {
    public Shader bloomShader;
    private Material bloomMaterial = null;

    [Range(0, 4)]
    public int iterations = 3;
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;
    [Range(1, 8)]
    public int downSampe = 2;
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;

    public Material material
    {
        get
        {
            if(bloomMaterial == null)
            {
                bloomMaterial = new Material(bloomShader);
            }
            return bloomMaterial;
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
            int rtW = src.width / downSampe;
            int rtH = src.height / downSampe;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(src, material, 0);

            for(int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 2);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(src, dest, material, 3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
