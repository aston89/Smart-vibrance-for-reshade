// Baudelaire's *smart vibrance shader*
// Enhance vibrance (saturation) witouth burning or glowing the color while preserving clarity in dark zones


#include "ReShade.fxh"

float3 BoostSaturation(float3 color, float saturationBoost, float grayscaleThreshold)
{
    // Calculate current saturation level
    float chroma = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);
    float saturation = (chroma == 0.0) ? 0.0 : chroma / (1.0 - abs(1.0 - (color.r + color.g + color.b) / 3.0));

    // Check if the saturation is below the grayscale threshold
    if (saturation < grayscaleThreshold)
    {
        // Apply saturation boost only if the color is not grayscale
        float3 boostedColor = color + saturationBoost * (1.0 - saturation) * (color - 0.5);

        // Ensure color values are within valid range
        boostedColor = saturate(boostedColor);

        return boostedColor;
    }
    else
    {
        // If the color is grayscale, return the original color
        return color;
    }
}


float4 PS_SaturationBoost(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Sample input texture from ReShade's back buffer
    float4 inputColor = tex2D(ReShade::BackBuffer, texcoord);

    // Define grayscale threshold (adjust as needed)
    float grayscaleThreshold = 0.2; // Example threshold value

    // Boost saturation with rolloff for non-grayscale colors
    float3 boostedColor = BoostSaturation(inputColor.rgb, 0.5, grayscaleThreshold);

    // Return adjusted color with original alpha
    return float4(boostedColor, inputColor.a);
}


technique SaturationBoost
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SaturationBoost;
    }
}
