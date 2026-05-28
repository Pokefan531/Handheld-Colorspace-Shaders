// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to correct the gamma curves for each RGB channels that the filter uses from Nintendo Switch Online GBA filter. It darkens the gamma that came default for NSO GBA.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw, 1=NSO-GBA" 1.0 0.0 2.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -1.0 1.0 0.05

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

  int GBAGamma[32];
  GBAGamma[0] = 0;     GBAGamma[1] = 1;     GBAGamma[2] = 3;     GBAGamma[3] = 6;
  GBAGamma[4] = 11;    GBAGamma[5] = 17;    GBAGamma[6] = 23;    GBAGamma[7] = 31;
  GBAGamma[8] = 37;    GBAGamma[9] = 45;    GBAGamma[10] = 52;   GBAGamma[11] = 60;
  GBAGamma[12] = 69;   GBAGamma[13] = 77;   GBAGamma[14] = 85;   GBAGamma[15] = 93;
  GBAGamma[16] = 103;  GBAGamma[17] = 112;  GBAGamma[18] = 121;  GBAGamma[19] = 130;
  GBAGamma[20] = 140;  GBAGamma[21] = 150;  GBAGamma[22] = 160;  GBAGamma[23] = 169;
  GBAGamma[24] = 179;  GBAGamma[25] = 191;  GBAGamma[26] = 201;  GBAGamma[27] = 211;
  GBAGamma[28] = 222;  GBAGamma[29] = 233;  GBAGamma[30] = 244;  GBAGamma[31] = 255;

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
  else
  {
    out_r = GBAGamma[RampR];
    out_g = GBAGamma[RampG];
    out_b = GBAGamma[RampB];
  }

  vec3 output_f = vec3(float(out_r), float(out_g), float(out_b));

  output_f *= (1.0 / 255.0);
  vec3 final_gamma = vec3(2.2 / (adjust_gamma + 2.2));

  gl_FragColor = vec4(pow(output_f, final_gamma), img.a);
}
#endif
