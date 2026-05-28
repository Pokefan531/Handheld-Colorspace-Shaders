/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from a PSP 1000 Model.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter mode "Color Profile (1=sRGB, 2=DCI, 3=Adobe, 4=Rec2020)" 1.0 1.0 4.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float mode;
#else
#define mode 1.0
#endif

#define target_gamma 2.2
#define display_gamma 2.2

#if defined(VERTEX)
attribute vec4 VertexCoord;
attribute vec4 TexCoord;
varying vec2 vTexCoord;
uniform mat4 MVPMatrix;

void main()
{
  gl_Position = MVPMatrix * VertexCoord;
  vTexCoord = TexCoord.xy;
}

#elif defined(FRAGMENT)
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 vTexCoord;
uniform sampler2D Texture;

/*
 We'll define our color weights in this pattern:
  r,   rg,  rb,  0.0,  //red channel
  gr,  g,   gb,  0.0,  //green channel
  br,  bg,  b,   0.0,  //blue channel
  blr, blg, blb, lum   //alpha channel; we'll hide lum at the end, too
*/

const mat4 PSP_sRGB = mat4(
  0.9358, 0.0444, 0.0142, 0.0,  //red channel
  0.1928, 0.7898, 0.0063, 0.0,  //green channel
  -0.1286, 0.1658, 0.9795, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.8861   //alpha channel
);

const mat4 PSP_DCI = mat4(
  0.7775, 0.0740, 0.0321, 0.0,  //red channel
  0.2988, 0.7700, 0.0662, 0.0,  //green channel
  -0.0763, 0.1560, 0.9017, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.9291  //alpha channel
);

const mat4 PSP_Adobe = mat4(
  0.6819, 0.0444, 0.0154, 0.0,  //red channel
  0.3629, 0.7898, 0.0386, 0.0,  //green channel
  -0.0448, 0.1658, 0.9460, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9571   //alpha channel
);

const mat4 PSP_Rec2020 = mat4(
  0.6024, 0.1057, 0.0320, 0.0,  //red channel
  0.3813, 0.7396, 0.0783, 0.0,  //green channel
  0.0163, 0.1547, 0.8897, 0.0,  //blue channel
  0.0,   0.0,  0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = PSP_sRGB;
    else if (color_mode == 2) profile = PSP_DCI;
    else if (color_mode == 3) profile = PSP_Adobe;
    else profile = PSP_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
