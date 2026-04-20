#include "ReShade.fxh"

// user controls
uniform float Intensity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 3.0;
> = 1.5;

uniform float SatPivot <
    ui_type = "slider";
    ui_min = 0.2; ui_max = 1.0;
> = 0.5;

uniform float GrayPivot <
    ui_type = "slider";
    ui_min = 0.0005; ui_max = 0.01;
> = 0.003;

uniform float GraySharpness <
    ui_type = "slider";
    ui_min = 5.0; ui_max = 80.0;
> = 45.0;


// sigmoid for smooth gating
float sigmoid(float x)
{
    return 1.0 / (1.0 + exp(-x));
}

float3 SmartVibrance(float3 color)
{
    // perceptual luminance
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));

    float3 chroma = color - luminance;

    float chromaEnergy = dot(chroma, chroma);
    float chromaMag = sqrt(chromaEnergy);

    // normalized saturation
    float normSat = saturate(chromaMag / SatPivot);

    // rolloff for already saturated colors
    float rolloff = 1.0 - normSat;

    // smooth grayscale protection
    float graySoft = sigmoid((GrayPivot - chromaEnergy) * GraySharpness);

    // unified response
    float response = lerp(rolloff, 1.0, graySoft);

    // apply intensity
    float gain = (Intensity - 1.0) * response;

    float3 result = luminance + chroma + chroma * gain;

    return saturate(result);
}

float4 PS_SmartVibrance(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 inputColor = tex2D(ReShade::BackBuffer, texcoord);

    float3 outColor = SmartVibrance(inputColor.rgb);

    return float4(outColor, inputColor.a);
}

technique SmartVibrance
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SmartVibrance;
    }
}
