/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from a Gameboy SP 101 (backlit version), aka AGS-101.

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

const mat4 SP1_sRGB = mat4(
  1.0050, 0.0412, -0.0094, 0.0,  //red channel
  0.0722, 0.8738, -0.0546, 0.0,  //green channel
  -0.0772, 0.0850, 1.0640, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9283   //alpha channel
);

const mat4 SP1_DCI = mat4(
  0.8339, 0.0732, 0.0116, 0.0,  //red channel
  0.2145, 0.8472, 0.0148, 0.0,  //green channel
  -0.0484, 0.0796, 0.9736, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.9538  //alpha channel
);

const mat4 SP1_Adobe = mat4(
  0.7305, 0.0412, -0.0073, 0.0,  //red channel
  0.3005, 0.8738, -0.0164, 0.0,  //green channel
  -0.0310, 0.0850, 1.0237, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9699   //alpha channel
);

const mat4 SP1_Rec2020 = mat4(
  0.6438, 0.1073, 0.0117, 0.0,  //red channel
  0.3306, 0.8078, 0.0292, 0.0,  //green channel
  0.0256, 0.0849, 0.9591, 0.0,  //blue channel
  0.0,   0.0,   0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = SP1_sRGB;
    else if (color_mode == 2) profile = SP1_DCI;
    else if (color_mode == 3) profile = SP1_Adobe;
    else profile = SP1_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
