/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from all Gameboy Color revisions and all manufactured by Sharp.

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

const mat4 GBC_sRGB = mat4(
  0.8944, 0.1091, 0.1447, 0.0,  //red channel
  0.2179, 0.6312, 0.2837, 0.0,  //green channel
  -0.1125, 0.2597, 0.5716, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.8989   //alpha channel
);

const mat4 GBC_DCI = mat4(
  0.7551, 0.1352, 0.1549, 0.0,  //red channel
  0.2913, 0.6174, 0.3077, 0.0,  //green channel
  -0.0464, 0.2474, 0.5374, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9557   //alpha channel
);

const mat4 GBC_Adobe = mat4(
  0.6708, 0.1091, 0.1432, 0.0,  //red channel
  0.3357, 0.6312, 0.2980, 0.0,  //green channel
  -0.0065, 0.2597, 0.5588, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9935   //alpha channel
);

const mat4 GBC_Rec2020 = mat4(
  0.6034, 0.1638, 0.1539, 0.0,  //red channel
  0.3569, 0.5987, 0.3132, 0.0,  //green channel
  0.0397, 0.2375, 0.5329, 0.0,  //blue channel
  0.0,  0.0,  0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = GBC_sRGB;
    else if (color_mode == 2) profile = GBC_DCI;
    else if (color_mode == 3) profile = GBC_Adobe;
    else profile = GBC_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
