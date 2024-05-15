*Smart vibrance shader*

This reshade shader is designed to enhance the vibrance of an image selectively, it works in this way :
1) Boost the saturation of every color if its below a certain threshold.
2) If the color have an amount of saturation already over the threshold, it will receive less and lesser boost until nothing will be boosted, this method prevent clipping, burning and glowing.
3) If the color is literally a grayscale (or near grayscale) the boost will also be decreased to preserve clarity and intelligibility on certain situation were the scene is dark and otherwise details will be lost.

The shader is fully commented and configurable, there's should be no need for further explanation.






