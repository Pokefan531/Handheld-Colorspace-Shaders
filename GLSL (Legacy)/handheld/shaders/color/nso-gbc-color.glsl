/*
 Shader Modified: Pokefan531
 Color Mangler
 Author: hunterk
 License: Public domain
 */

// Shader that replicates the Nintendo Switch Online's GBC color filter.
// (Requires to use the nso-gbc-gamma shader from the folder before loading this shader. Or use a preset from color-mod folder to load automatically)

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter black_level "Raise Black Levels to NSO-GBC filter" 1.0 0.0 1.0 1.0
#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float black_level;
#else
#define black_level 1.0
#endif

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

const mat4 NSO_GBC_sRGB = mat4(
  0.84, 0.11, 0.1525, 0.0,  //red channel
  0.2625, 0.675, 0.305, 0.0,  //green channel
  0.0, 0.245, 0.53, 0.0,  //blue channel
  0.0,  0.0,  0.0,  1.0   //alpha channel
);

void main()
{
    vec4 screen = texture2D(Texture, vTexCoord).rgba;

    mat4 profile;
	profile = NSO_GBC_sRGB;

    float lum_scale = profile[3].w;
    screen.rgb = clamp(screen.rgb * lum_scale, 0.0, 1.0);
    screen = profile * screen;
    vec3 blackraise = (screen.rgb + (black_level * 0.175)) / (1.0 + (black_level * 0.175));
    gl_FragColor = vec4(blackraise, screen.a);
}
#endif
