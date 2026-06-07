# fastsave
A Minecraft mod to make your generated chunks to write into your ssd faster while running mods like Chunky and prevent your memory from filling up.

I kept running into the same problem: my RAM would fill up while playing Minecraft, and the game would start stuttering badly whenever it tried to save chunks. It wasn't a fancy server setup or anything — just me playing, watching the memory climb, and waiting for the freezes to stop.
After a while I got annoyed enough to actually look into why. Turns out Minecraft's default chunk saving is pretty naive — it blocks the main thread and writes each chunk one by one with small, scattered disk operations. On a busy world with a lot of loaded chunks, this creates a traffic jam between RAM and disk, and your game feels it.
So I wrote this mod. FastSave hooks into the chunk saving pipeline and pre-serializes chunk data before it hits the disk, tracking writes asynchronously instead of making the game wait. It's not a miracle fix, but it takes some of the pressure off and makes the whole process a bit less painful.
Built for Minecraft 1.20.1 with Fabric.

If you run into some issues, contact me on discord: brewgar
