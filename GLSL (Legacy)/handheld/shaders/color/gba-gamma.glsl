// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBA's LCD gamma curves, as both the GBA and the SP-001 uses its own curve that isn't a typical pure power gamma curve even if almost close with different contrast. This is also presented without black compensation, so full visible curves shown.
// A gamma can be adjusted as GBA's gamma can vary depending on the light source angle. Top light angle is darker while the bottom light angle is lighter. On Adjust Gamma, GBA can go from -0.85 to 1.25 from light to dark by light angle, while the SP-001 can range from -0.6 to 0.6 on the Adjust Gamma settings.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw, 1=GBA, 2=SP001" 1.0 0.0 2.0 1.0
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

  int GBAGamma[32];
  GBAGamma[0] = 0;   GBAGamma[1] = 3;   GBAGamma[2] = 6;   GBAGamma[3] = 10;
  GBAGamma[4] = 15;  GBAGamma[5] = 25;  GBAGamma[6] = 36;  GBAGamma[7] = 50;
  GBAGamma[8] = 62;  GBAGamma[9] = 71;  GBAGamma[10] = 82; GBAGamma[11] = 92;
  GBAGamma[12] = 102; GBAGamma[13] = 109; GBAGamma[14] = 116; GBAGamma[15] = 124;
  GBAGamma[16] = 131; GBAGamma[17] = 138; GBAGamma[18] = 145; GBAGamma[19] = 152;
  GBAGamma[20] = 160; GBAGamma[21] = 168; GBAGamma[22] = 176; GBAGamma[23] = 184;
  GBAGamma[24] = 193; GBAGamma[25] = 202; GBAGamma[26] = 211; GBAGamma[27] = 218;
  GBAGamma[28] = 229; GBAGamma[29] = 240; GBAGamma[30] = 249; GBAGamma[31] = 255;

  int GBASPGamma[32];
  GBASPGamma[0] = 0;   GBASPGamma[1] = 2;   GBASPGamma[2] = 5;   GBASPGamma[3] = 8;
  GBASPGamma[4] = 13;  GBASPGamma[5] = 20;  GBASPGamma[6] = 28;  GBASPGamma[7] = 39;
  GBASPGamma[8] = 49;  GBASPGamma[9] = 57;  GBASPGamma[10] = 66; GBASPGamma[11] = 75;
  GBASPGamma[12] = 84;  GBASPGamma[13] = 90;  GBASPGamma[14] = 97;  GBASPGamma[15] = 105;
  GBASPGamma[16] = 111; GBASPGamma[17] = 119; GBASPGamma[18] = 125; GBASPGamma[19] = 133;
  GBASPGamma[20] = 141; GBASPGamma[21] = 149; GBASPGamma[22] = 158; GBASPGamma[23] = 167;
  GBASPGamma[24] = 176; GBASPGamma[25] = 187; GBASPGamma[26] = 197; GBASPGamma[27] = 207;
  GBASPGamma[28] = 220; GBASPGamma[29] = 235; GBASPGamma[30] = 247; GBASPGamma[31] = 255;

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
    out_r = GBAGamma[RampR];
    out_g = GBAGamma[RampG];
    out_b = GBAGamma[RampB];
  }
  else if (g_mode == 2)
  {
    out_r = GBASPGamma[RampR];
    out_g = GBASPGamma[RampG];
    out_b = GBASPGamma[RampB];
  }

  vec3 output_f = vec3(float(out_r), float(out_g), float(out_b));

  output_f *= (1.0 / 255.0);
  vec3 final_gamma = vec3(2.2 / (adjust_gamma + 2.2));

  gl_FragColor = vec4(pow(output_f, final_gamma), img.a);
}
#endif
