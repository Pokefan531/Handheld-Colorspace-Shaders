#version 450

// GBA-Gamma shader pass by Pokefan531
// Based on stock shader to add gamma control
// This is used for GBA shaders with just simple gamma adjustment. Also mGBA fix is adjusting the RGB balance to bring green to 255 from 251 in the libretro core to bring a proper white and grey balance.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float mgba_fix;
	float adjust_gamma;
} params;

#pragma parameter mgba_fix "mGBA Fix" 0.0 0.0 1.0 1.0
#pragma parameter adjust_gamma "Adjust Gamma" 2.2 1.0 4.0 0.05

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

void main()
{
    vec4 color = texture(Source, vTexCoord);
    color.rgb *= vec3(1.0, (1.0 + (0.016 * params.mgba_fix)), 1.0);
    color.rgb = pow(color.rgb, vec3(params.adjust_gamma / 2.2));
    FragColor = color;
}
