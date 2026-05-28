/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from both Gameboy Advance revision (cicra late 2001) and all Gameboy Advance SP that uses frontlit LCDs, aka AGS-001. This colorspace comes from Panasonic's GBA screen and uses 32-pin connector, and is the most common display you would fine for later GBA and all SP-001.

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

const mat4 SP0_sRGB = mat4(
  0.8774, 0.1186, 0.1772, 0.0,  //red channel
  0.2702, 0.6383, 0.2531, 0.0,  //green channel
  -0.1476, 0.2431, 0.5697, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.8714   //alpha channel
);

const mat4 SP0_DCI = mat4(
  0.7427, 0.1438, 0.1849, 0.0,  //red channel
  0.3355, 0.6261, 0.2813, 0.0,  //green channel
  -0.0783, 0.2301, 0.5338, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9274   //alpha channel
);

const mat4 SP0_Adobe = mat4(
  0.6613, 0.1186, 0.1748, 0.0,  //red channel
  0.3750, 0.6383, 0.2690, 0.0,  //green channel
  -0.0363, 0.2431, 0.5562, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9650   //alpha channel
);

const mat4 SP0_Rec2020 = mat4(
  0.5972, 0.1717, 0.1835, 0.0,  //red channel
  0.3907, 0.6085, 0.2873, 0.0,  //green channel
  0.0121, 0.2198, 0.5292, 0.0,  //blue channel
  0.0,  0.0,  0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = SP0_sRGB;
    else if (color_mode == 2) profile = SP0_DCI;
    else if (color_mode == 3) profile = SP0_Adobe;
    else profile = SP0_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
