/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from a Nintendo DS Lite.

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

const mat4 DSL_sRGB = mat4(
  0.9310, 0.0350, 0.0069, 0.0,  //red channel
  0.1024, 0.8781, -0.0515, 0.0,  //green channel
  -0.0334, 0.0869, 1.0446, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9677   //alpha channel
);

const mat4 DSL_DCI = mat4(
  0.7720, 0.0648, 0.0247, 0.0,  //red channel
  0.2401, 0.8524, 0.0184, 0.0,  //green channel
  -0.0121, 0.0828, 0.9569, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.9880  //alpha channel
);

const mat4 DSL_Adobe = mat4(
  0.6758, 0.0350, 0.0080, 0.0,  //red channel
  0.3234, 0.8781, -0.0133, 0.0,  //green channel
  0.0008, 0.0869, 1.0053, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9869   //alpha channel
);

const mat4 DSL_Rec2020 = mat4(
  0.5960, 0.0966, 0.0245, 0.0,  //red channel
  0.3512, 0.8140, 0.0328, 0.0,  //green channel
  0.0528, 0.0894, 0.9427, 0.0,  //blue channel
  0.0,   0.0,   0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = DSL_sRGB;
    else if (color_mode == 2) profile = DSL_DCI;
    else if (color_mode == 3) profile = DSL_Adobe;
    else profile = DSL_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
