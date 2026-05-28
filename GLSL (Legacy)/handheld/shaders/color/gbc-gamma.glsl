// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBC's LCD gamma curves, as it doesn't use the standard gamma. The GBC screen has a brighter image overall, with the dark shadows being darker for a more contrast look from the display.
// A gamma can be adjusted as GBC's gamma can vary depending on the light source angle. Top light angle is brighter while the bottom light angle is darker. Still is overall brighter than raw RGB gamma ramp.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw, 1=GBC" 1.0 0.0 1.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -1.0 1.25 0.05

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float gamma_mode;
uniform COMPAT_PRECISION float adjust_gamma;
#else
#define gamma_mode 1.0
#define adjust_gamma 0.0
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

int conv_sample(float f)
{
  return (f >= 1.0) ? 255 : ((f <= 0.0) ? 0 : int(floor(f * 256.0)));
}

void main()
{
  int OGGamma[32];
  OGGamma[0] = 0;   OGGamma[1] = 8;   OGGamma[2] = 16;  OGGamma[3] = 24;
  OGGamma[4] = 33;  OGGamma[5] = 41;  OGGamma[6] = 49;  OGGamma[7] = 57;
  OGGamma[8] = 66;  OGGamma[9] = 74;  OGGamma[10] = 82; OGGamma[11] = 90;
  OGGamma[12] = 99; OGGamma[13] = 107; OGGamma[14] = 115; OGGamma[15] = 123;
  OGGamma[16] = 132; OGGamma[17] = 140; OGGamma[18] = 148; OGGamma[19] = 156;
  OGGamma[20] = 165; OGGamma[21] = 173; OGGamma[22] = 181; OGGamma[23] = 189;
  OGGamma[24] = 198; OGGamma[25] = 206; OGGamma[26] = 214; OGGamma[27] = 222;
  OGGamma[28] = 231; OGGamma[29] = 239; OGGamma[30] = 247; OGGamma[31] = 255;

  int GBCGamma[32];
  GBCGamma[0] = 0;   GBCGamma[1] = 8;   GBCGamma[2] = 15;  GBCGamma[3] = 26;
  GBCGamma[4] = 37;  GBCGamma[5] = 49;  GBCGamma[6] = 67;  GBCGamma[7] = 85;
  GBCGamma[8] = 97;  GBCGamma[9] = 110; GBCGamma[10] = 121; GBCGamma[11] = 134;
  GBCGamma[12] = 140; GBCGamma[13] = 148; GBCGamma[14] = 154; GBCGamma[15] = 160;
  GBCGamma[16] = 170; GBCGamma[17] = 180; GBCGamma[18] = 188; GBCGamma[19] = 196;
  GBCGamma[20] = 202; GBCGamma[21] = 207; GBCGamma[22] = 212; GBCGamma[23] = 217;
  GBCGamma[24] = 222; GBCGamma[25] = 228; GBCGamma[26] = 232; GBCGamma[27] = 237;
  GBCGamma[28] = 246; GBCGamma[29] = 252; GBCGamma[30] = 254; GBCGamma[31] = 255;

  vec4 img = texture2D(Texture, vTexCoord);

  int r_int = conv_sample(img.r);
  int g_int = conv_sample(img.g);
  int b_int = conv_sample(img.b);

  int RampR = r_int / 8;
  int RampG = g_int / 8;
  int RampB = b_int / 8;

  if (RampR > 31) RampR = 31;
  if (RampG > 31) RampG = 31;
  if (RampB > 31) RampB = 31;

  int g_mode = int(gamma_mode + 0.5);

  int out_r, out_g, out_b;

  if (g_mode == 0)
  {
    out_r = OGGamma[RampR];
    out_g = OGGamma[RampG];
    out_b = OGGamma[RampB];
  }
  else if (g_mode == 1)
  {
    out_r = GBCGamma[RampR];
    out_g = GBCGamma[RampG];
    out_b = GBCGamma[RampB];
  }

  vec3 output_f = vec3(float(out_r), float(out_g), float(out_b));

  output_f *= (1.0 / 255.0);
  vec3 final_gamma = vec3(2.2 / (adjust_gamma + 2.2));

  gl_FragColor = vec4(pow(output_f, final_gamma), img.a);
}
#endif
