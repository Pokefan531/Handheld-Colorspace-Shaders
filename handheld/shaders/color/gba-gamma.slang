#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to use GBA's LCD gamma curves, as both the GBA and the SP-001 uses its own curve that isn't a typical pure power gamma curve even if almost close with less contrast. This is also presented without black compensation, so full visible curves shown.
// A gamma can be adjusted as GBA's gamma can vary depending on the light source angle. Top light angle is darker while the bottom light angle is lighter. On Adjust Gamma, GBA can go from -0.5 to 0.5 from light to dark by light angle, while the SP-001 can range from -0.6 to 0.6 on the Adjust Gamma settings.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float gamma_mode;
	float adjust_gamma;
} params;

#pragma parameter gamma_mode "Gamma Ramp: 0=Raw,1=GBA,2=GBA+Colortemp" 1.0 0.0 2.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma (Darker-Brighter)" 0.0 -0.6 0.6 0.05

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

const uint GBAGamma[32] = {
      0x00, 0x05, 0x0a, 0x14, 0x1d, 0x2a, 0x36, 0x43,
      0x4c, 0x54, 0x5d, 0x66, 0x6d, 0x73, 0x79, 0x7f,
      0x85, 0x8b, 0x91, 0x97, 0x9d, 0xa4, 0xab, 0xb2,
      0xba, 0xc3, 0xcb, 0xd3, 0xde, 0xeb, 0xf7, 0xff,
    };

const uint GBAGammaR[32] = {
      0x00, 0x08, 0x10, 0x1a, 0x22, 0x32, 0x41, 0x4e,
      0x58, 0x61, 0x69, 0x72, 0x7a, 0x80, 0x85, 0x8b,
      0x90, 0x95, 0x9b, 0xa1, 0xa7, 0xad, 0xb3, 0xb8,
      0xbf, 0xc8, 0xd0, 0xd7, 0xe0, 0xec, 0xf7, 0xff,
    };

const uint GBAGammaG[32] = {
      0x00, 0x02, 0x04, 0x0e, 0x19, 0x21, 0x2c, 0x38,
      0x42, 0x4a, 0x52, 0x5b, 0x62, 0x68, 0x6e, 0x74,
      0x7b, 0x82, 0x89, 0x8c, 0x94, 0x9b, 0xa2, 0xaa,
      0xb3, 0xbc, 0xc4, 0xcc, 0xda, 0xe8, 0xf6, 0xff,
    };

const uint GBAGammaB[32] = {
      0x00, 0x07, 0x0f, 0x18, 0x20, 0x2d, 0x3a, 0x46,
      0x50, 0x58, 0x61, 0x6b, 0x72, 0x78, 0x7e, 0x84,
      0x8a, 0x90, 0x96, 0x9d, 0xa5, 0xac, 0xb4, 0xbb,
      0xc3, 0xcc, 0xd4, 0xdb, 0xe6, 0xf2, 0xfa, 0xff,
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
        R = GBAGamma[RampR];
        G = GBAGamma[RampG];
        B = GBAGamma[RampB];
    }
    else if (gamma_mode == 2.0)
	{
        R = GBAGammaR[RampR];
        G = GBAGammaG[RampG];
        B = GBAGammaB[RampB];
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
