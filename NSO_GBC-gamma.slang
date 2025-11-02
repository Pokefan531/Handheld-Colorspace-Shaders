#version 450

// Based on the ss-gamma-ramp shader by Overload's ramp from bsnes
// Modified by Pokefan531
// This gamma ramp is used to correct the gamma curves for each RGB channels that the filter uses from Nintendo Switch Online GBC filter. It uses colder gamma ramps and helps out to replicate the look when loading the NSO-GBC shader afterwards.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

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

const uint gammaRampR[32] = {
      0x00, 0x00, 0x00, 0x01, 0x04, 0x08, 0x0e, 0x15,
      0x1c, 0x26, 0x2f, 0x39, 0x42, 0x4e, 0x5a, 0x67,
      0x72, 0x7f, 0x8a, 0x97, 0xa3, 0xaf, 0xba, 0xc6,
      0xcf, 0xd7, 0xe1, 0xe9, 0xf0, 0xf7, 0xfc, 0xff,
    };

const uint gammaRampG[32] = {
      0x01, 0x03, 0x08, 0x0c, 0x13, 0x1c, 0x23, 0x2f,
      0x38, 0x42, 0x4e, 0x59, 0x66, 0x70, 0x7f, 0x8c,
      0x97, 0xa6, 0xb1, 0xbc, 0xc8, 0xd2, 0xdb, 0xe4,
      0xeb, 0xf1, 0xf8, 0xfa, 0xff, 0xff, 0xff, 0xff,
    };

const uint gammaRampB[32] = {
      0x01, 0x07, 0x0e, 0x16, 0x1b, 0x28, 0x32, 0x3c,
      0x47, 0x54, 0x5c, 0x6a, 0x76, 0x82, 0x8d, 0x9a,
      0xa6, 0xb1, 0xbe, 0xc7, 0xd2, 0xd9, 0xe3, 0xeb,
      0xf0, 0xf8, 0xfa, 0xfe, 0xff, 0xff, 0xff, 0xff,
    };

#define conv(f) ((f >= 1.0) ? 255 : (f <= 0.0 ? 0 : int(floor(f * 256.0))))

void main()
{
	vec4 img = texture(Source, vTexCoord);

	// convert standard vec4 to uint color values
	uvec4 int_img = uvec4(conv(img.r), conv(img.g), conv(img.b), conv(img.a));

	uint r = (int_img.r) & 0xff;
	uint g = (int_img.g) & 0xff;
	uint b = (int_img.b) & 0xff;

	// apply the ramp
	uint R = gammaRampR[r >> 3];
	uint G = gammaRampG[g >> 3];
	uint B = gammaRampB[b >> 3];

	uvec3 output_i = uvec3(R, G, B);
	vec3  output_f = vec3(output_i) * vec3(1./255.);

	FragColor = vec4(output_f, 1.0);
}
