/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the Vivid mode of Nintendo Switch OLED Model.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter mode "Color Profile (1=sRGB, 2=DCI, 3=Adobe, 4=Rec2020)" 1.0 1.0 4.0 1.0
#pragma parameter white_toggle "Full White Scale" 1.0 0.0 1.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float mode;
uniform COMPAT_PRECISION float white_toggle;
#else
#define mode 1.0
#define white 1.0
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

const mat4 SWITCH_sRGB = mat4(
  1.4335, -0.0467, -0.0216, 0.0,  //red channel
  -0.3889, 1.0625, -0.0756, 0.0,  //green channel
  -0.0446, -0.0158, 1.0972, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.6976   //alpha channel
);

const mat4 SWITCH_sRGB_white = mat4(
  1.4335, -0.0467, -0.0216, 0.0,  //red channel
  -0.3889, 1.0625, -0.0756, 0.0,  //green channel
  -0.0446, -0.0158, 1.0972, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

const mat4 SWITCH_DCI = mat4(
  1.1708, 0.0025, 0.0014, 0.0,  //red channel
  -0.1313, 1.0143, 0.0014, 0.0,  //green channel
  -0.0395, -0.0168, 0.9972, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.8541  //alpha channel
);

const mat4 SWITCH_DCI_white = mat4(
  1.1708, 0.0025, 0.0014, 0.0,  //red channel
  -0.1313, 1.0143, 0.0014, 0.0,  //green channel
  -0.0395, -0.0168, 0.9972, 0.0,  //blue channel
  0.0,   0.0,   0.0,   1.0  //alpha channel
);

const mat4 SWITCH_Adobe = mat4(
  1.0119, -0.0467, -0.0227, 0.0,  //red channel
  0.0245, 1.0625, -0.0288, 0.0,  //green channel
  -0.0364, -0.0158, 1.0515, 0.0,  //blue channel
  0.0,  0.0,  0.0,  0.9412   //alpha channel
);

const mat4 SWITCH_Adobe_white = mat4(
  1.0119, -0.0467, -0.0227, 0.0,  //red channel
  0.0245, 1.0625, -0.0288, 0.0,  //green channel
  -0.0364, -0.0158, 1.0515, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

const mat4 SWITCH_Rec2020 = mat4(
  0.8832, 0.0559, 0.0000, 0.0,  //red channel
  0.1025, 0.9493, 0.0194, 0.0,  //green channel
  0.0143, -0.0052, 0.9806, 0.0,  //blue channel
  0.0,   0.0,  0.0,   0.9948  //alpha channel
);

const mat4 SWITCH_Rec2020_white = mat4(
  0.8832, 0.0559, 0.0000, 0.0,  //red channel
  0.1025, 0.9493, 0.0194, 0.0,  //green channel
  0.0143, -0.0052, 0.9806, 0.0,  //blue channel
  0.0,   0.0,  0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    bool white = bool(white_toggle);
    if (color_mode == 1) profile = (!white) ? SWITCH_sRGB : SWITCH_sRGB_white;
    else if (color_mode == 2) profile = (!white) ? SWITCH_DCI : SWITCH_DCI_white;
    else if (color_mode == 3) profile = (!white) ? SWITCH_Adobe : SWITCH_Adobe_white;
    else profile = (!white) ? SWITCH_Rec2020 : SWITCH_Rec2020_white;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
