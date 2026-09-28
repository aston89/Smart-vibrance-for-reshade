#include "ReShade.fxh"

// =============================================================================
// Smart Vibrance PRO
// -----------------------------------------------------------------------------
// ReShade / Pixel Shader
//
// Evolution of Smart Vibrance PLUS.
//
// PRO refactors the boost-balance model itself:
//
//   - separates luminance from chroma
//   - estimates chromatic direction using two opponent-style axes
//   - continuously balances the chroma response across the full hue plane
//   - applies stronger restraint to low/mid-chroma colours
//   - preserves dynamic saturation for colours that can support it
//
// The goal is NOT maximum saturation.
// The goal is controlled chroma expansion with better distribution of the
// available boost across hue, chroma strength and scene conditions.
//
// PRO is general-purpose and is not tied to any specific content type.
// =============================================================================


// =============================================================================
// USER CONTROLS
// =============================================================================

// Base boost intensity.
uniform float Intensity <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 3.0;
    ui_step = 0.01;
    ui_label = "Intensity";
    ui_tooltip = "Overall adaptive chroma boost.";
> = 1.5;


// Saturation pivot used by the original adaptive rolloff.
uniform float SatPivot <
    ui_type = "slider";
    ui_min = 0.2;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Saturation Pivot";
    ui_tooltip = "Controls where chroma rolloff begins.";
> = 0.5;


// Near-neutral pivot inherited from PLUS.
uniform float GrayPivot <
    ui_type = "slider";
    ui_min = 0.0005;
    ui_max = 0.01;
    ui_step = 0.0001;
    ui_label = "Gray Pivot";
    ui_tooltip = "Controls the transition into the near-neutral response region.";
> = 0.003;


// Sharpness of the near-neutral transition.
uniform float GraySharpness <
    ui_type = "slider";
    ui_min = 5.0;
    ui_max = 80.0;
    ui_step = 1.0;
    ui_label = "Gray Sharpness";
    ui_tooltip = "Controls how quickly the near-neutral response changes.";
> = 45.0;


// =============================================================================
// PRO HUE BALANCE
// =============================================================================
// These are relative response budgets for the four main opponent directions.
// Lower value = stronger restraint.
// Higher value = more of the original boost is preserved.
// Mixed colours are continuously interpolated between these directions.
// Defaults mirror the validated PotPlayer PRO model.

uniform float ProRedResponse <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "PRO Red Response";
    ui_tooltip = "Relative chroma boost budget for the red direction.";
> = 0.50;


uniform float ProYellowResponse <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "PRO Yellow Response";
    ui_tooltip = "Relative chroma boost budget for the yellow direction.";
> = 0.68;


uniform float ProGreenResponse <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "PRO Green Response";
    ui_tooltip = "Relative chroma boost budget for the green direction.";
> = 0.90;


uniform float ProBlueResponse <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "PRO Blue Response";
    ui_tooltip = "Relative chroma boost budget for the blue direction.";
> = 0.92;


// Response fallback when chroma is too weak to make hue direction reliable.
uniform float ProNeutralResponse <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "PRO Neutral Response";
    ui_tooltip = "Fallback response for colours very close to neutral.";
> = 0.58;

// =============================================================================
// PRO CHROMA BALANCE
// =============================================================================
//
// Protection is strongest in the low/mid-chroma region and progressively
// fades as chroma becomes stronger.
//
// This is what prevents weak colours from automatically receiving the same
// aggressive boost as clearly defined colours.
//

uniform float ProChromaStart <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.3;
    ui_step = 0.005;
    ui_label = "PRO Chroma Start";
    ui_tooltip = "Start of the low/mid-chroma balancing region.";
> = 0.075;


uniform float ProChromaEnd <
    ui_type = "slider";
    ui_min = 0.05;
    ui_max = 0.5;
    ui_step = 0.005;
    ui_label = "PRO Chroma End";
    ui_tooltip = "End of the low/mid-chroma balancing region.";
> = 0.26;


// Amount of chroma required before hue direction becomes reliable.
uniform float ProHueConfidence <
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 0.1;
    ui_step = 0.001;
    ui_label = "PRO Hue Confidence";
    ui_tooltip = "Chroma level required before directional hue balancing becomes fully active.";
> = 0.020;


// =============================================================================
// BASIC UTILITY
// =============================================================================

float sigmoid(float x)
{
    return 1.0 / (1.0 + exp(-x));
}


// =============================================================================
// CONTINUOUS HUE RESPONSE
// =============================================================================
// Two lightweight opponent-style axes:
//
//     A = Red <-> Green
//     B = Yellow <-> Blue
//
// The four response values act as continuous control points across the
// chromatic plane.
// No hard hue classification is performed.
// =============================================================================

float HueResponse(float a, float b)
{
    float redWeight =
        max(a, 0.0);

    float greenWeight =
        max(-a, 0.0);

    float yellowWeight =
        max(b, 0.0);

    float blueWeight =
        max(-b, 0.0);

    float total =
        redWeight +
        greenWeight +
        yellowWeight +
        blueWeight +
        1e-5;

    return
    (
        redWeight    * ProRedResponse +
        yellowWeight * ProYellowResponse +
        greenWeight  * ProGreenResponse +
        blueWeight   * ProBlueResponse
    ) / total;
}

// =============================================================================
// SMART VIBRANCE PRO
// =============================================================================

float3 SmartVibrancePRO(float3 color)
{
    // -------------------------------------------------------------------------
    // Luminance
    // -------------------------------------------------------------------------

    float luminance =
        dot(
            color,
            float3(
                0.2126,
                0.7152,
                0.0722
            )
        );


    // -------------------------------------------------------------------------
    // Chroma relative to luminance
    // -------------------------------------------------------------------------

    float3 chroma =
        color - luminance;

    float chromaEnergy =
        dot(
            chroma,
            chroma
        );

    float chromaMag =
        sqrt(chromaEnergy);


    // =========================================================================
    // ORIGINAL PLUS RESPONSE
    // =========================================================================

    // Normalized saturation.
    float normSat =
        saturate(
            chromaMag / SatPivot
        );

    // Roll off colours that are already strongly saturated.
    float rolloff =
        1.0 - normSat;

    // Smooth near-neutral response.
    float graySoft =
        sigmoid(
            (GrayPivot - chromaEnergy) *
            GraySharpness
        );

    // Original PLUS response.
    float response =
        lerp(
            rolloff,
            1.0,
            graySoft
        );


    // =========================================================================
    // PRO OPPONENT COORDINATES
    // =========================================================================
    //
    // A:
    //     positive = red
    //     negative = green
    //
    // B:
    //     positive = yellow
    //     negative = blue
    //
    // These are intentionally lightweight and ReShade-friendly.
    // =========================================================================

    float A =
        color.r -
        color.g;

    float B =
        (color.r + color.g) * 0.5 -
        color.b;


    // -------------------------------------------------------------------------
    // Continuous hue response
    // -------------------------------------------------------------------------

    float hueResponse =
        HueResponse(
            A,
            B
        );


    // -------------------------------------------------------------------------
    // Hue confidence
    // Very weak chroma has an unstable hue direction.
    // Blend toward the neutral response in that region.
    // -------------------------------------------------------------------------

    float hueConfidence =
        saturate(
            chromaMag /
            ProHueConfidence
        );

    float balancedResponse =
        lerp(
            ProNeutralResponse,
            hueResponse,
            hueConfidence
        );


    // =========================================================================
    // CHROMA-DEPENDENT BALANCING
    // =========================================================================

    // Protection begins at ProChromaStart and fades toward ProChromaEnd.
    float chromaPosition =
        saturate(
            (chromaMag - ProChromaStart) /
            max(
                ProChromaEnd -
                ProChromaStart,
                1e-5
            )
        );

    // Invert so low chroma receives the strongest balancing.
    float chromaFade =
        1.0 -
        chromaPosition;

    // Smooth transition.
    chromaFade =
        chromaFade *
        chromaFade *
        (3.0 - 2.0 * chromaFade);


    // -------------------------------------------------------------------------
    // Calculate how much of the original response should be restrained.
    //
    // balancedResponse = 1.0
    //     -> no additional restriction
    //
    // balancedResponse = 0.50
    //     -> strong restriction
    // -------------------------------------------------------------------------

    float protection =
        chromaFade *
        (
            1.0 -
            balancedResponse
        );


    // Apply PRO balance to the original PLUS response.
    response *=
        1.0 -
        protection;


    // =========================================================================
    // FINAL CHROMA BOOST
    // =========================================================================

    float gain =
        (Intensity - 1.0) *
        response;

    float3 result =
        luminance +
        chroma +
        chroma * gain;


    return saturate(result);
}


// =============================================================================
// PIXEL SHADER
// =============================================================================

float4 PS_SmartVibrancePRO(
    float4 vpos : SV_Position,
    float2 texcoord : TexCoord) : SV_Target
{
    float4 inputColor =
        tex2D(
            ReShade::BackBuffer,
            texcoord
        );

    float3 outColor =
        SmartVibrancePRO(
            inputColor.rgb
        );

    return float4(
        outColor,
        inputColor.a
    );
}


// =============================================================================
// TECHNIQUE
// =============================================================================

technique SmartVibrancePRO
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SmartVibrancePRO;
    }
}