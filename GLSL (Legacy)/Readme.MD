This folder's content is meant to be dragged inside the "shaders_glsl" folder within Retroarch shader directory. The entire folder should not be dragged inside the folder, but the content inside should.

This shader is meant to use under GL Retroarch driver for those who can't use slang shaders due to lack of support of GLCore in Retroarch currently and can't either have access to Vulkan, or have poor Vulkan support. These shaders work on any OpenGL 2.0 or GLES 2.0 capable GPUs.

Useful for Android devices with only GL support or portable handhelds that runs ARM Linux that only works with OpenGL or OpenGL ES.

The Legacy Status is only posted as much simple shaders to run well with hardly any GPU penalty from GL2 era. The main updates will be taken place under Slang shaders, while the GLSL shaders will only update just the matrix numbers or gamma in much lesser amount. It was ported from slang to glsl with the help of Gemini, with me polishing the code at the end and making it work to test on retroarch to see if it completely works. So far all worked well on Retroarch GL driver.
