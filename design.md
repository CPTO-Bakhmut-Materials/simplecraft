# Love2D minecraft clone

We need to build a 3d voxel game as simple as possible clone of minecraft

Goals
1) We do not strive to have 1-to-1 parity, approximations of features are fine
2) We should use third-party libraries, but only if implementation of feature is expensive and would require a lot of code
3) We should have a precreated small chunk of world, just for a test. This should eliminate generation code for the world
4) We only need to have free camera movement and ability to place dirt block and destory any block. But we dont need to save changes that user made. The file on disk with the world is only for reading
5) The world format should be some kind of opensource format which can be edited by third-party and vizualized by it. So we dont need to create our own tools. E.g - .vox 
6) No menus and no UI beyond the HUD needed to play: the crosshair, on-screen touch controls (joystick and buttons) for devices without a keyboard, and a toggle between mouse/keyboard and touch controls
7) There should be a different types of block, lets say stone, dirt, dirt with grass. Use opensource textures for them.
8) No collision
9) Use free opensource voxel/block assets

It is important to use best-practices and generate production-grade code