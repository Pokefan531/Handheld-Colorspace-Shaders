#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the LCD Colorspace from a PSP 1000 Model --

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

const mat4 PSP_sRGB = mat4(
	0.9675, 0.0425, 0.02, 0.0,  //red channel
	0.185, 0.79, 0.013, 0.0,  //green channel
	-0.1525, 0.1675, 0.967, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.8675   //alpha channel
); 

const mat4 PSP_DCI = mat4(
	0.804, 0.074, 0.038, 0.0,  //red channel
	0.295, 0.770, 0.072, 0.0,  //green channel
	-0.099, 0.156, 0.89, 0.0,  //blue channel
	0.0,   0.0,   0.0,   0.91  //alpha channel
); 

const mat4 PSP_Adobe = mat4(
	0.70, 0.043, 0.021, 0.0,  //red channel
	0.355, 0.789, 0.044, 0.0,  //green channel
	-0.055, 0.168, 0.935, 0.0,  //blue channel
	0.0,  0.0,  0.0,  0.9475   //alpha channel
);

const mat4 PSP_Rec2020 = mat4(
	0.619, 0.105, 0.0375, 0.0,  //red channel
	0.379, 0.74, 0.085, 0.0,  //green channel
	0.002, 0.155, 0.8775,  0.0,  //blue channel
	0.0,   0.0,  0.0,   1.0  //alpha channel
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

	if (color_mode == 1) profile = PSP_sRGB;
	else if (color_mode == 2) profile = PSP_DCI;
	else if (color_mode == 3) profile = PSP_Adobe;
	else if (color_mode == 4) profile = PSP_Rec2020;
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
