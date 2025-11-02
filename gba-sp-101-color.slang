#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from a Gameboy SP 101 (backlit version), aka AGS-101. --

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	float mode;
} global;

#pragma parameter mode "Color Profile (1=sRGB,2=DCI,3=Adobe,4=Rec2020)" 1.0 1.0 4.0 1.0
int color_mode = int(global.mode);

#define target_gamma 2.2
#define display_gamma 2.2

/*
We'll define our color weights in this pattern:
	r,   rg,  rb,  0.0,  //red channel
	gr,  g,   gb,  0.0,  //green channel
	br,  bg,  b,   0.0,  //blue channel
	blr, blg, blb, lum   //alpha channel; we'll hide lum at the end, too
*/

const mat4 SP1_sRGB = mat4(
	0.965, 0.0345, -0.002, 0.0,  //red channel
	0.11, 0.89, -0.04, 0.0,  //green channel
	-0.075, 0.0755, 1.042, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.93   //alpha channel
); 

const mat4 SP1_DCI = mat4(
	0.80, 0.065, 0.017, 0.0,  //red channel
	0.2475, 0.8625, 0.029, 0.0,  //green channel
	-0.0475, 0.0725, 0.954, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.955  //alpha channel
); 

const mat4 SP1_Adobe = mat4(
	0.699, 0.034, -0.002, 0.0,  //red channel
	0.331, 0.89, -0.004, 0.0,  //green channel
	-0.03, 0.076, 1.006, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.97   //alpha channel
);

const mat4 SP1_Rec2020 = mat4(
	0.616, 0.098, 0.017, 0.0,  //red channel
	0.36, 0.823, 0.043, 0.0,  //green channel
	0.024, 0.079, 0.94, 0.0,  //blue channel
	0.0,   0.0,   0.0,   1.0  //alpha channel
); 

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out mat4 profile;

void main()
{
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;

	if (color_mode == 1) profile = SP1_sRGB;
	else if (color_mode == 2) profile = SP1_DCI;
	else if (color_mode == 3) profile = SP1_Adobe;
	else if (color_mode == 4) profile = SP1_Rec2020;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in mat4 profile;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	// bring out our stored luminance value
	float lum = profile[3].w;

	// our adjustments need to happen in linear gamma
	vec4 screen = pow(texture(Source, vTexCoord), vec4(target_gamma)).rgba;

	screen = clamp(screen * lum, 0.0, 1.0);
	screen = profile * screen;
	FragColor = pow(screen, vec4(1.0 / display_gamma));
}
