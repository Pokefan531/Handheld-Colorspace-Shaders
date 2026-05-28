/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the LCD dynamics from a GameBoy Advance based from VBA-M and No$GBA.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter mode "Reduce Contrast to match VBA/No$GBA filter" 1.0 0.0 1.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float mode;
#else
#define mode 1.0
#endif

#define target_gamma 1.45
#define display_gamma 1.45

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

const mat4 VBA_COLOR1 = mat4(
  0.73, 0.0825, 0.0825, 0.0,  //red channel
  0.27, 0.6775, 0.24, 0.0,  //green channel
  0.0, 0.24, 0.6775, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

const mat4 VBA_COLOR2 = mat4(
  0.68, 0.0825, 0.0825, 0.0,  //red channel
  0.24, 0.6775, 0.24, 0.0,  //green channel
  0.0, 0.24, 0.6775, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

void main()
{
    vec4 screen = pow(texture2D(Texture, vTexCoord), vec4(target_gamma));

    mat4 profile;
    int color_mode = int(mode + 0.5);
    if (color_mode == 0) profile = VBA_COLOR1;
    else profile = VBA_COLOR2;

    float lum_scale = profile[3].w;
    screen = clamp(screen * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    screen = pow(screen, vec4(1.0 / display_gamma));
    vec3 blackraise = (screen.rgb + (mode * 0.2)) / (1.0 + (mode * 0.333));
    gl_FragColor = vec4(blackraise, screen.a);
}
#endif
