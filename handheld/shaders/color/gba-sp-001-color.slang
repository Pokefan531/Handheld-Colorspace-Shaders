#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from both Gameboy Advance revision (cicra late 2001) and all Gameboy Advance SP that uses frontlit LCDs, aka AGS-001. This colorspace comes from Panasonic's GBA screen and uses 32-pin connector, and is the most common display you would fine for OG GBA. --

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

const mat4 GBA_sRGB = mat4(
	0.7875, 0.1175, 0.1775, 0.0,  //red channel
	0.3025, 0.6325, 0.2125, 0.0,  //green channel
	-0.09, 0.25, 0.61, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9175   //alpha channel
); 

const mat4 GBA_DCI = mat4(
	0.665, 0.14, 0.1825, 0.0,  //red channel
	0.36, 0.62, 0.245, 0.0,  //green channel
	-0.025, 0.24, 0.5725, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.975  //alpha channel
);

const mat4 GBA_Adobe = mat4(
	0.595, 0.1175, 0.1725, 0.0,  //red channel
	0.395, 0.6325, 0.23, 0.0,  //green channel
	0.01, 0.25, 0.5975, 0.0,  //blue channel
	0.0,  0.0,  0.0,  1.0   //alpha channel
); 

const mat4 GBA_Rec2020 = mat4(
	0.5375, 0.165, 0.18, 0.0,  //red channel
	0.405, 0.605, 0.25, 0.0,  //green channel
	0.055, 0.23, 0.57, 0.0,  //blue channel
	0.0,  0.0,  0.0,   1.0  //alpha channel
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

	if (color_mode == 1) profile = GBA_sRGB;
	else if (color_mode == 2) profile = GBA_DCI;
	else if (color_mode == 3) profile = GBA_Adobe;
	else if (color_mode == 4) profile = GBA_Rec2020;
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
