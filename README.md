*Smart vibrance shader*

This reshade shader is designed to enhance the vibrance of an image selectively, it works in this way :
1) Boost the saturation of every color if its below a certain threshold.
2) If the color have an amount of saturation already over the threshold, it will receive less and lesser boost until nothing will be boosted, this method prevent clipping, burning and glowing.
3) If the color is literally a grayscale (or near grayscale) the boost will also be decreased to preserve clarity and intelligibility on certain situation were the scene is dark and otherwise details will be lost.

This shader is the equivalent of the NVIDIA "RTX Dynamic Vibrance" new feature but witouth the need of AI cores, the logic behind is extremely similar and the result is almost the same especially if you don't already have other gamma, brightness, contrast and digital filter alterations applied to your game.

The shader is fully commented and configurable, there's should no need for further explanation, in case, just ask.
Click on the file .fx and then click on download button on the right or copy paste the code into a .txt and rename it to .fx

ReShade forum link for discussion : 
https://reshade.me/forum/shader-presentation/9475-smart-vibrance-shader-shader-version-of-rtx-dynamic-vibrance

V2 RELEASE UPDATE :
. changed the way the grayscale is detected, now it doesnt simply switch from on to off but gragually decrease the boost factor the more the pixel is near the grayscale, you can select the threshold in the gui.
. boost amount, rolloff threshold and grayscale detection threshold are now configurable in the UI of reshade.

Preview : 
![alt text](https://github.com/aston89/Smart-vibrance-for-reshade/blob/main/reshade_smart_vibrance.jpg?raw=true)






