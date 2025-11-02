#version 450

/*
   Shader Modified: Pokefan531
   Color Mangler
   Author: hunterk
   License: Public domain
*/
// Shader that replicates the Nintendo Switch Online's GBC color filter --
// (Requires to use the NSO-gbc-gamma shader from the folder before loading this shader. Or use a preset from color-mod folder to load automatically)

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
	float black_level;
} global;

#pragma parameter black_level "Raise Black Levels to NSO-GBC filter" 1.0 0.0 1.0 1.0

/*
We'll define our color weights in this pattern:
	r,   rg,  rb,  0.0,  //red channel
	gr,  g,   gb,  0.0,  //green channel
	br,  bg,  b,   0.0,  //blue channel
	blr, blg, blb, lum   //alpha channel; we'll hide lum at the end, too
*/

const mat4 NSO_GBC_sRGB = mat4(
	0.84, 0.11, 0.1525, 0.0,  //red channel
	0.2625, 0.675, 0.305, 0.0,  //green channel
	0.0, 0.245, 0.53, 0.0,  //blue channel
	0.0,  0.0,  0.0,  1.0   //alpha channel
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

	profile = NSO_GBC_sRGB;
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
	vec4 screen = texture(Source, vTexCoord).rgba;

	screen = clamp(screen * lum, 0.0, 1.0);
	screen = profile * screen;
	vec3 blackraise = (screen.rgb + (global.black_level * 0.175)) / (1.0 + (global.black_level * 0.175));
	FragColor = vec4(blackraise, screen.a);
}
