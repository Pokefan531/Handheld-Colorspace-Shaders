// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to correct the gamma curves for each RGB channels that the filter uses from Nintendo Switch Online GBC filter. It uses colder gamma ramps and helps out to replicate the look when loading the NSO-GBC shader afterwards.

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
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
  int gammaRampR[32];
  gammaRampR[0] = 0;   gammaRampR[1] = 0;   gammaRampR[2] = 0;   gammaRampR[3] = 1;
  gammaRampR[4] = 4;   gammaRampR[5] = 8;   gammaRampR[6] = 14;  gammaRampR[7] = 21;
  gammaRampR[8] = 28;  gammaRampR[9] = 38;  gammaRampR[10] = 47; gammaRampR[11] = 57;
  gammaRampR[12] = 66; gammaRampR[13] = 78; gammaRampR[14] = 90; gammaRampR[15] = 103;
  gammaRampR[16] = 114; gammaRampR[17] = 127; gammaRampR[18] = 138; gammaRampR[19] = 151;
  gammaRampR[20] = 163; gammaRampR[21] = 175; gammaRampR[22] = 186; gammaRampR[23] = 198;
  gammaRampR[24] = 207; gammaRampR[25] = 215; gammaRampR[26] = 225; gammaRampR[27] = 233;
  gammaRampR[28] = 240; gammaRampR[29] = 247; gammaRampR[30] = 252; gammaRampR[31] = 255;

  int gammaRampG[32];
  gammaRampG[0] = 1;   gammaRampG[1] = 3;   gammaRampG[2] = 8;   gammaRampG[3] = 12;
  gammaRampG[4] = 19;  gammaRampG[5] = 28;  gammaRampG[6] = 35;  gammaRampG[7] = 47;
  gammaRampG[8] = 56;  gammaRampG[9] = 66;  gammaRampG[10] = 78; gammaRampG[11] = 89;
  gammaRampG[12] = 102; gammaRampG[13] = 112; gammaRampG[14] = 127; gammaRampG[15] = 140;
  gammaRampG[16] = 151; gammaRampG[17] = 166; gammaRampG[18] = 177; gammaRampG[19] = 188;
  gammaRampG[20] = 200; gammaRampG[21] = 210; gammaRampG[22] = 219; gammaRampG[23] = 228;
  gammaRampG[24] = 235; gammaRampG[25] = 241; gammaRampG[26] = 248; gammaRampG[27] = 250;
  gammaRampG[28] = 255; gammaRampG[29] = 255; gammaRampG[30] = 255; gammaRampG[31] = 255;

  int gammaRampB[32];
  gammaRampB[0] = 1;   gammaRampB[1] = 7;   gammaRampB[2] = 14;  gammaRampB[3] = 22;
  gammaRampB[4] = 27;  gammaRampB[5] = 40;  gammaRampB[6] = 50;  gammaRampB[7] = 60;
  gammaRampB[8] = 71;  gammaRampB[9] = 84;  gammaRampB[10] = 92; gammaRampB[11] = 106;
  gammaRampB[12] = 118; gammaRampB[13] = 130; gammaRampB[14] = 141; gammaRampB[15] = 154;
  gammaRampB[16] = 166; gammaRampB[17] = 177; gammaRampB[18] = 190; gammaRampB[19] = 199;
  gammaRampB[20] = 210; gammaRampB[21] = 217; gammaRampB[22] = 227; gammaRampB[23] = 235;
  gammaRampB[24] = 240; gammaRampB[25] = 248; gammaRampB[26] = 250; gammaRampB[27] = 254;
  gammaRampB[28] = 255; gammaRampB[29] = 255; gammaRampB[30] = 255; gammaRampB[31] = 255;

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

  int out_r, out_g, out_b;

  {
    out_r = gammaRampR[RampR];
    out_g = gammaRampG[RampG];
    out_b = gammaRampB[RampB];
  }

  vec3 output_f = vec3(float(out_r), float(out_g), float(out_b));

  output_f *= (1.0 / 255.0);

  gl_FragColor = vec4(output_f, 1.0);
}
#endif
