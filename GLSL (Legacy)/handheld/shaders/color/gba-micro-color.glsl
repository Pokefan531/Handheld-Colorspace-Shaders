/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from a Gameboy Micro (OXY-001).

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

const mat4 GBM_sRGB = mat4(
  0.7702, 0.1001, 0.1123, 0.0,  //red channel
  0.3253, 0.6837, 0.0990, 0.0,  //green channel
  -0.0955, 0.2162, 0.7887, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9128   //alpha channel
);

const mat4 GBM_DCI = mat4(
  0.6513, 0.1223, 0.1227, 0.0,  //red channel
  0.3889, 0.6718, 0.1452, 0.0,  //green channel
  -0.0402, 0.2059, 0.7321, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9614   //alpha channel
);

const mat4 GBM_Adobe = mat4(
  0.5793, 0.1001, 0.1118, 0.0,  //red channel
  0.4274, 0.6837, 0.1230, 0.0,  //green channel
  -0.0067, 0.2162, 0.7652, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9933   //alpha channel
);

const mat4 GBM_Rec2020 = mat4(
  0.5211, 0.1465, 0.1220, 0.0,  //red channel
  0.4335, 0.6523, 0.1541, 0.0,  //green channel
  0.0454, 0.2012, 0.7239, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = GBM_sRGB;
    else if (color_mode == 2) profile = GBM_DCI;
    else if (color_mode == 3) profile = GBM_Adobe;
    else profile = GBM_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
