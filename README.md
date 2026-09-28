# Smart Vibrance Shader (ReShade)
A real-time adaptive vibrance shader for games that imitates NVIDIA RTX Dynamic Vibrance witouth needing an nvidia gpu. Not a simple saturation filter. Not a global “digital vibrance” boost.
This shader selectively enhances color **based on what is already present in each pixel**, avoiding the typical overprocessed look.

---

##  Problem
Most games, especially when played on PC monitors, tend to look:
- slightly washed-out  
- inconsistent in saturation across scenes  
- overly dependent on post-processing or display settings  

Common fixes don’t really solve the problem:
- **GPU vibrance sliders** boost everything equally, oversaturate already strong colors.
- **contrast / brightness tweaks** destroy shadow or highlight detail.
- **post-processing chains** add complexity without fixing the core issue.

---

## Core idea
Instead of applying a fixed saturation boost:
- the shader evaluates how “colorful” each pixel already is  
- applies less and less boost as saturation increases

Meaning:
- weak colors → boosted  
- mid-range colors → gently enhanced  
- strong colors → left untouched  

---

## How it works

### 1. adaptive saturation boost
Low-saturation pixels receive more enhancement.

### 2. smooth rolloff
As saturation increases, the boost fades out progressively.

**No hard cutoffs, no abrupt transitions.**

---

### 3. grayscale protection
Near-neutral pixels are preserved using a smooth response.

This prevents:
- noise amplification  
- shadow detail loss  
- flat areas (e.g. UI, fog, anime shading) breaking apart  

---

## Difference between Base vs PLUS vs PRO logic

### Base version (`Smart_Vibrance.fx`):
* threshold-based behavior
* simple rolloff using smoothstep
* basic grayscale detection
* straightforward saturation boost with limited adaptive balancing
* computationally very lightweight
* Works well, but can feel slightly “mechanical” in edge cases

### PLUS version (`Smart_Vibrance_Plus.fx`):
* fully continuous response (no hard logic switches)
* chroma-based analysis instead of simple RGB heuristics
* smoother grayscale transition using sigmoid shaping
* more natural interaction with already saturated content
* better adaptive handling of low- and mid-saturation colors
* More computationally demanding than Base, while remaining lightweight
Behaves more like a system, less like a filter.

### PRO version (`Smart_Vibrance_PRO.fx`):
* refactors the boost-balance model itself rather than simply increasing the strength of PLUS
* uses a continuous opponent-style chroma representation based on two axes:
  * Red to Green
  * Yellow to Blue
* evaluates chromatic direction continuously across the full hue plane
* assigns different chroma-response budgets to different hue directions
* smoothly interpolates between those directions instead of using hard hue categories
* introduces chroma-dependent balancing, so low- and mid-chroma colors are no longer automatically treated as candidates for maximum boost
* uses a neutral fallback when chroma is too weak for reliable hue-direction estimation
* preserves the continuous response and adaptive behavior introduced by PLUS
* allows the chroma response to be shaped independently for Red, Yellow, Green and Blue
* designed as a general-purpose adaptive vibrance model rather than being tied to a specific type of content
* computationally more demanding than PLUS, but still lightweight enough for real-time ReShade use
Behaves less like a saturation filter and more like a **continuous chroma-budget system**.

**In short:**
* Base : simple and lightweight adaptive vibrance
* PLUS : smoother, more continuous and more natural adaptive vibrance
* PRO : hue-aware and chroma-aware boost balancing with finer control over how vibrance is distributed across the image

**Works especially well on:**
- SDR games  
- older titles with flat color grading  
- games with heavy compression / post effects  

---

## Important note
This is not a color-accurate tool.

It is designed for:
> perceptual enhancement during gameplay

Not for:
- color grading
- reference accuracy
- professional pipelines

---

## Usage
- Drop the `.fx` file into your ReShade shaders folder  
- Enable it from the ReShade menu  
- Adjust parameters in real time  

Recommended starting point:
- Intensity: ~1.5  
- SatPivot: ~0.5  

---

## Discussion
https://reshade.me/forum/shader-presentation/9475-smart-vibrance-shader-shader-version-of-rtx-dynamic-vibrance

---

## note:

The PLUS version also change the original threshold-based grayscale logic with a continuous response curve to solve:
- abrupt transitions  
- edge artifacts in low-saturation areas  
and results in a much smoother and more natural image behavior.

---

## ReShade forum link for discussion: 
https://reshade.me/forum/shader-presentation/9475-smart-vibrance-shader-shader-version-of-rtx-dynamic-vibrance

---

## Preview : 
![alt text](https://github.com/aston89/Smart-vibrance-for-reshade/blob/main/preview.jpg?raw=true)



