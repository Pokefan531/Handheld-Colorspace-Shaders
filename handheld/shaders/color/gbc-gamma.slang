#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBC's LCD gamma curves, as it doesn't use the standard gamma. The GBC screen has a brighter image overall, with the dark shadows being darker for a more contrast look from the display.
// A gamma can be adjusted as GBC's gamma can vary depending on the light source angle. Top light angle is brighter while the bottom light angle is darker. Still is overall brighter than raw RGB gamma ramp.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float gamma_mode;
	float adjust_gamma;
} params;

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw, 1=GBC, 2=GBC+Colortemp" 1.0 0.0 2.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -0.5 1.0 0.05

#define gamma_mode params.gamma_mode

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

const uint OGGamma[32] = {
      0x00, 0x08, 0x10, 0x19, 0x21, 0x29, 0x31, 0x3a,
      0x42, 0x4a, 0x52, 0x5a, 0x63, 0x6b, 0x73, 0x7b,
      0x84, 0x8c, 0x94, 0x9c, 0xa4, 0xad, 0xb5, 0xbd,
      0xc5, 0xce, 0xd6, 0xde, 0xe6, 0xee, 0xf7, 0xff,
    };

const uint GBCGamma[32] = {
      0x00, 0x06, 0x0b, 0x15, 0x22, 0x30, 0x3f, 0x52,
      0x5e, 0x69, 0x77, 0x84, 0x8b, 0x90, 0x97, 0x9d,
      0xa8, 0xb1, 0xbb, 0xc3, 0xc9, 0xcf, 0xd4, 0xd9,
      0xe0, 0xe6, 0xeb, 0xf0, 0xf8, 0xfc, 0xfe, 0xff,
    };

const uint GBCGammaR[32] = {
      0x00, 0x08, 0x0c, 0x15, 0x23, 0x31, 0x40, 0x52,
      0x5e, 0x69, 0x76, 0x82, 0x88, 0x8c, 0x92, 0x99,
      0xa4, 0xac, 0xb5, 0xbe, 0xc4, 0xca, 0xd1, 0xd4,
      0xde, 0xe4, 0xe9, 0xef, 0xf8, 0xfb, 0xfe, 0xff,
    };

const uint GBCGammaG[32] = {
      0x00, 0x05, 0x0c, 0x17, 0x23, 0x30, 0x40, 0x53,
      0x5f, 0x6a, 0x79, 0x86, 0x8e, 0x95, 0x9b, 0xa2,
      0xad, 0xb6, 0xbf, 0xc8, 0xcf, 0xd3, 0xd8, 0xde,
      0xe3, 0xe9, 0xed, 0xf0, 0xf8, 0xfc, 0xfe, 0xff,
    };

const uint GBCGammaB[32] = {
      0x00, 0x03, 0x07, 0x0f, 0x1f, 0x2e, 0x3d, 0x4f,
      0x5a, 0x65, 0x72, 0x7f, 0x84, 0x8a, 0x90, 0x97,
      0xa2, 0xab, 0xb4, 0xbd, 0xc1, 0xc8, 0xd0, 0xd3,
      0xde, 0xe4, 0xeb, 0xef, 0xf9, 0xfc, 0xfe, 0xff,
    };

uvec3 GammaAdjustment(uint r, uint g, uint b)
{
    uint RampR = uint(r >> 3);
    uint RampG = uint(g >> 3);
    uint RampB = uint(b >> 3);

    uint R, G, B;

    if (gamma_mode == 0.0)
	{
        R = OGGamma[RampR];
        G = OGGamma[RampG];
        B = OGGamma[RampB];
    }
    else if (gamma_mode == 1.0)
	{
        R = GBCGamma[RampR];
        G = GBCGamma[RampG];
        B = GBCGamma[RampB];
    }
    else if (gamma_mode == 2.0)
	{
        R = GBCGammaR[RampR];
        G = GBCGammaG[RampG];
        B = GBCGammaB[RampB];
	}
    return uvec3(R, G, B);
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define conv(f) ((f >= 1.0) ? 255 : (f <= 0.0 ? 0 : int(floor(f * 256.0))))

void main()
{
	vec4 img = texture(Source, vTexCoord);

	// convert standard vec4 to uint color values
	uvec4 int_img = uvec4(conv(img.r), conv(img.g), conv(img.b), conv(img.a));

	uint r = (int_img.r) & 0xff;
	uint g = (int_img.g) & 0xff;
	uint b = (int_img.b) & 0xff;

	uvec3 output_i = GammaAdjustment(r, g, b);
	vec3  output_f = vec3(output_i) * vec3(1./255.);
	FragColor = vec4(pow(output_f, vec3(2.2 / (params.adjust_gamma + 2.2))), img.a);
}
