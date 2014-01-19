FlixelRotatedCollisionTest
==========================

Testing/improving rotated pixel perfect collision in HaxeFlixel.

progress
---------

 * Working out on pixel perfect collision code to hopefully found a way to make it faster enough to be usable on non-flash targets.
 * Interactive demo to test it.
 * First efforts (NoCache and NewCache) were a step forward but still buggy in some cases.
 * Added a (quite _naive_) BMDPool class to reuse temp BitmapData.
 * Added DebugCollision to spot bugs in my previous attempts (pixels ByteArrays not aligned/bad size, so giving wrong results).
 * Improved BMDPool class (hitRatio stays around 0.95 - good!).
 * FinalCollision is the latest iteration of the code (with and without pooling).
 * FinalUnifiedCollision uses _practically_ the same code for Flash and non-Flash targets (uses pooling and performs slightly better than the previous Flash implementations with the blend color trick).
 * Experimental GetPixelCollision... because! (... but _unexpectedly_ resulted slower than the Final ones).
 * Alternative BMDPool implemented with List instead of Array (typedef in ICollision).
 * Experimental OddEvenCollision: checks even pixels first (seems to perform _sligthly_ better BUT is less easier to read - don't like, doesn't worth it!).
 
You can check it right away by running it: the collision code is independent from HaxeFlixel (for testing purposes), calls local classes.

![screenshot00-cpp_release.png](screenshot00-cpp_release.png)
