/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD Colorspace from a Nintendo DS Phat.

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

const mat4 NDS_sRGB = mat4(
  0.8427, 0.0986, 0.0930, 0.0,  //red channel
  0.2600, 0.6387, 0.1560, 0.0,  //green channel
  -0.1027, 0.2627, 0.7510, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.9069   //alpha channel
);

const mat4 NDS_DCI = mat4(
  0.7106, 0.1234, 0.1062, 0.0,  //red channel
  0.3272, 0.6261, 0.1927, 0.0,  //green channel
  -0.0378, 0.2505, 0.7011, 0.0,  //blue channel
  0.0,   0.0,   0.0,   0.9636  //alpha channel
);

const mat4 NDS_Adobe = mat4(
  0.6308, 0.0986, 0.0932, 0.0,  //red channel
  0.3679, 0.6387, 0.1759, 0.0,  //green channel
  0.0013, 0.2627, 0.7309, 0.0,  //blue channel
  0.0,   0.0,   0.0,   1.0   //alpha channel
);

const mat4 NDS_Rec2020 = mat4(
  0.5653, 0.1500, 0.1057, 0.0,  //red channel
  0.3802, 0.6071, 0.2002, 0.0,  //green channel
  0.0545, 0.2429, 0.6941, 0.0,  //blue channel
  0.0,   0.0,   0.0,   1.0  //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 1) profile = NDS_sRGB;
    else if (color_mode == 2) profile = NDS_DCI;
    else if (color_mode == 3) profile = NDS_Adobe;
    else profile = NDS_Rec2020;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    gl_FragColor = pow(screen, vec4(1.0 / display_gamma));
}
#endif
