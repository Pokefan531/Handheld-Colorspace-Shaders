#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from a Nintendo DS Phat --

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

const mat4 NDS_sRGB = mat4(
	0.83, 0.095, 0.0975, 0.0,  //red channel
	0.27, 0.645, 0.165, 0.0,  //green channel
	-0.10, 0.26, 0.7375, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.91   //alpha channel
); 

const mat4 NDS_DCI = mat4(
	0.70, 0.1175, 0.1125, 0.0,  //red channel
	0.34, 0.635, 0.20, 0.0,  //green channel
	-0.04, 0.2475, 0.6875, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.96  //alpha channel
); 

const mat4 NDS_Adobe = mat4(
	0.625, 0.095, 0.098, 0.0,  //red channel
	0.38, 0.645, 0.185, 0.0,  //green channel
	-0.005, 0.26, 0.717, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.995   //alpha channel
);

const mat4 NDS_Rec2020 = mat4(
	0.557, 0.145, 0.11, 0.0,  //red channel
	0.391, 0.615, 0.2075, 0.0,  //green channel
	0.052, 0.24, 0.6825, 0.0,  //blue channel
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

	if (color_mode == 1) profile = NDS_sRGB;
	else if (color_mode == 2) profile = NDS_DCI;
	else if (color_mode == 3) profile = NDS_Adobe;
	else if (color_mode == 4) profile = NDS_Rec2020;
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
