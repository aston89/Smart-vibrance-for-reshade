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

## Difference between Base vs PLUS logic

### Base version (Smart_vibrance.fx):
- threshold-based behavior  
- simple rolloff using smoothstep  
- grayscale detection with limited smoothness
Works well, but can feel slightly “mechanical” in edge cases.

### PLUS version (Smart_vibrance_Plus.fx):
- fully continuous response (no hard logic switches)  
- chroma-based analysis (more stable than RGB heuristics)  
- smoother grayscale transition using sigmoid shaping  
- more natural interaction with already saturated content  
Behaves more like a system, less like a filter

**In practice:**
- colors feel more alive without looking artificial  
- already vibrant scenes remain stable  
- dark scenes keep their detail  
- UI and neutral tones stay clean  

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



