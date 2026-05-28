/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from the Gameboy Advance early revisions (up to late 2001) that uses Sharp's manufactured displays. GBA's Sharp displays are the ones that are found on many 40-pin connectors.

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

const mat4 GBA_sRGB = mat4(
  0.8988, 0.1163, 0.1831, 0.0,  //red channel
  0.2229, 0.6217, 0.2438, 0.0,  //green channel
  -0.1217, 0.2620, 0.5731, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.8915   //alpha channel
);

const mat4 GBA_DCI = mat4(
  0.7599, 0.1423, 0.1905, 0.0,  //red channel
  0.2937, 0.6084, 0.2708, 0.0,  //green channel
  -0.0536, 0.2493, 0.5387, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9491  //alpha channel
);

const mat4 GBA_Adobe = mat4(
  0.6759, 0.1163, 0.1803, 0.0,  //red channel
  0.3364, 0.6217, 0.2594, 0.0,  //green channel
  -0.0123, 0.2620, 0.5603, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9878   //alpha channel
);

const mat4 GBA_Rec2020 = mat4(
  0.6102, 0.1711, 0.1889, 0.0,  //red channel
  0.3551, 0.5898, 0.2768, 0.0,  //green channel
  0.0347, 0.2391, 0.5343, 0.0,  //blue channel
  0.0,  0.0,  0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = GBA_sRGB;
    else if (color_mode == 2) profile = GBA_DCI;
    else if (color_mode == 3) profile = GBA_Adobe;
    else profile = GBA_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
