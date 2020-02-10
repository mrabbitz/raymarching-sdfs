# Implicit Surface Planets
- Mike Rabbitz (mrabbitz)

## Citations
- https://www.shadertoy.com/user/amally
- http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
- http://www.iquilezles.org/www/articles/smin/smin.htm
- https://www.iquilezles.org/www/articles/sdfbounding/sdfbounding.htm
- University of Pennsylvania course material

## Live Demo
https://mrabbitz.github.io/raymarching-sdfs/

## Objectives
- Gain experience with signed distance functions
- Experiment with animation curves

## Techniques
# Bounding Volume Hierarchy

Using a 3D Box SDF, a dynamic bounding box is used to bound the sun, earth, and moon.  There is a nested dynamic bounding box that bounds the earth and moon once inside our outermost bounding box.  Both hierarchys are used in the Scene ray-marching operations.  The nested hierarchy is individually used in the ShadowTest ray-marching operations.

The width, height, and depth vectors (all originating from center of box with magnitude half of the respective width, height, or length) are based on the following logic.  We will use the outermost bounding box's width vector as the example:

The X bound for the earth is its radius plus the absolute value of the difference between its X position and the sun's X position.
The same goes for the X bound of the moon, substituting the moon's radius and X position, respectively.
The X bound of the sun is it's radius.
We then take the max value of these to determine the width vector of our bounding box.

# SDF Combination Operations

The earth is comprised of 5 sphere SDFs that are combined using a cubic polynomial smooth minimum function.  This gives the appearance of a bumpy/hilly surface.
The moon is comprised of 5 sphere SDFs that are combined using a non-smooth subtraction function.  This gives the appearance of a craters.

# Shading

The sun's color is based on a noise-function-based interpolation between two colors.
The earth's color is based on the intersection point's x, y, and z components relative to the radius of the earth.
The moon's color is gray.
Space's color is based on a noise function where returned values in a certain range are colored white (stars) and the rest is black.

The sun's and space's shading is simply determined through the color that is decided.  No lighting equations or shadow tests are involved.

With the earth and the moon, lambert's law along with a shadow test is used to determine the correct intensity of color for each shaded point.  A user-defined ambient term is used in order to give the appearance of global illumination.

# Earth and Moon Rotation

Using these Rotate Functions : https://www.shadertoy.com/view/3dj3Rc

The earth simply uses its position to rotate around the origin (sun).
The moon rotates around the origin and is then translated by the position of the earth.

The uniform Time variable is used to simulate smooth motion.
