package collisions;

// azrafe7 (final)

import collisions.ICollision.BMDPool;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;


using collisions.Extensions;	// temp workaround to have Rectangle.setTo() on all targets

class FinalCollision implements ICollision {
	public var debug:BitmapData = new BitmapData(1, 1, false);
	
	// Optimization: Local static vars to reduce allocations
	private var pointA:Point = new Point();
	private var pointB:Point = new Point();
	private var centerA:Point = new Point();
	private var centerB:Point = new Point();
	private var matrixA:Matrix = new Matrix();
	private var matrixB:Matrix = new Matrix();
	private var testMatrix:Matrix = new Matrix();
	private var boundsA:Rectangle = new Rectangle();
	private var boundsB:Rectangle = new Rectangle();
	
	public function new():Void 
	{
		
	}

	/**
	 * A Pixel Perfect Collision check between two FlxSprites.
	 * It will do a bounds check first, and if that passes it will run a pixel perfect match on the intersecting area.
	 * Works with rotated and animated sprites.
	 * May be slow, so use it sparingly.
	 * 
	 * @param	Contact			The first FlxSprite to test against
	 * @param	Target			The second FlxSprite to test again, sprite order is irrelevant
	 * @param	AlphaTolerance	The tolerance value above which alpha pixels are included. Default to 255 (must be fully opaque for collision).
	 * @param	Camera			If the collision is taking place in a camera other than FlxG.camera (the default/current) then pass it here
	 * @return	Boolean True if the sprites collide, false if not
	 */
	public function pixelPerfectCheck(Contact:FlxSprite, Target:FlxSprite, AlphaTolerance:Int = 255, ?Camera:FlxCamera):Bool
	{
		//if either of the angles are non-zero, consider the angles of the sprites in the pixel check
		var considerRotation:Bool = Contact.angle != 0 || Target.angle != 0;
		
		Camera = (Camera != null) ? Camera : FlxG.camera;
		
		pointA.x = Contact.x - Std.int(Camera.scroll.x * Contact.scrollFactor.x) - Contact.offset.x;
		pointA.y = Contact.y - Std.int(Camera.scroll.y * Contact.scrollFactor.y) - Contact.offset.y;
		
		pointB.x = Target.x - Std.int(Camera.scroll.x * Target.scrollFactor.x) - Target.offset.x;
		pointB.y = Target.y - Std.int(Camera.scroll.y * Target.scrollFactor.y) - Target.offset.y;
		
		if (considerRotation)
		{
			// find the center of both sprites
			centerA.setTo(Contact.origin.x, Contact.origin.y);
			centerB.setTo(Target.origin.x, Target.origin.y);			
			
			// now make a bounding box that allows for the sprite to be rotated in 360 degrees
			boundsA.setTo(
				(pointA.x + centerA.x - centerA.length), 
				(pointA.y + centerA.y - centerA.length), 
				centerA.length*2, centerA.length*2);
			boundsB.setTo(
				(pointB.x + centerB.x - centerB.length), 
				(pointB.y + centerB.y - centerB.length), 
				centerB.length*2, centerB.length*2);			
		}
		else
		{
			boundsA.setTo(pointA.x, pointA.y, Contact.frameWidth, Contact.frameHeight);
			boundsB.setTo(pointB.x, pointB.y, Target.frameWidth, Target.frameHeight);
		}
		
		var intersect:Rectangle = boundsA.intersection(boundsB);
		
		if (intersect.isEmpty() || intersect.width < 1 || intersect.height < 1)
		{
			return false;
		}
		
		//	Thanks to Chris Underwood for helping with the translate logic :)
		matrixA.identity();
		matrixA.translate(-(intersect.x - boundsA.x), -(intersect.y - boundsA.y));
		
		matrixB.identity();
		matrixB.translate(-(intersect.x - boundsB.x), -(intersect.y - boundsB.y));
		
	#if !flash
		Contact.drawFrame();
		Target.drawFrame();
	#end
		
		var testA:BitmapData = Contact.framePixels;
		var testB:BitmapData = Target.framePixels;
		
		var overlapWidth:Int = Std.int(intersect.width);
		var overlapHeight:Int = Std.int(intersect.height);
		
		// More complicated case, if either of the sprites is rotated
		if (considerRotation)
		{
			testMatrix.identity();
			
			// translate the matrix to the center of the sprite
			testMatrix.translate(-Contact.origin.x, -Contact.origin.y);
			
			// rotate the matrix according to angle
			testMatrix.rotate(Contact.angle * 0.017453293 );  // degrees to rad
			
			// translate it back!
			testMatrix.translate(boundsA.width / 2, boundsA.height / 2);
			
			// prepare an empty canvas
			var testA2:BitmapData = BMDPool.create(Math.floor(boundsA.width), Math.floor(boundsA.height), true, 0x00000000, false);
			
			// plot the sprite using the matrix
			testA2.draw(testA, testMatrix, null, null, null, false);
			testA = testA2;
			
			// (same as above)
			testMatrix.identity();
			testMatrix.translate(-Target.origin.x, -Target.origin.y);
			testMatrix.rotate(Target.angle * 0.017453293 );  // degrees to rad
			testMatrix.translate(boundsB.width / 2, boundsB.height / 2);
			
			var testB2:BitmapData = BMDPool.create(Math.floor(boundsB.width), Math.floor(boundsB.height), true, 0x00000000, false);
			testB2.draw(testB, testMatrix, null, null, null, false);			
			testB = testB2;
		}
		
	#if flash
		
		var overlapArea:BitmapData = new BitmapData(overlapWidth, overlapHeight, false);
		
		overlapArea.draw(testA, matrixA, new ColorTransform(1, 1, 1, 1, 255, -255, -255, AlphaTolerance), BlendMode.NORMAL);
		overlapArea.draw(testB, matrixB, new ColorTransform(1, 1, 1, 1, 255, 255, 255, AlphaTolerance), BlendMode.DIFFERENCE);
		
		// Developers: If you'd like to see how this works enable the debugger and display it in your game somewhere (only Flash target).
		debug = overlapArea;
		
		var overlap:Rectangle = overlapArea.getColorBoundsRect(0xffffffff, 0xff00ffff);
		overlap.offset(intersect.x, intersect.y);
		
		return (!overlap.isEmpty());
		
	#else
		
		boundsA.setTo(Std.int(-matrixA.tx), Std.int(-matrixA.ty), overlapWidth, overlapHeight);
		boundsB.setTo(Std.int(-matrixB.tx), Std.int(-matrixB.ty), overlapWidth, overlapHeight);

		var pixelsA = testA.getPixels(boundsA);
		var pixelsB = testB.getPixels(boundsB);
		
		var hit = false;
		
		// Analyze overlapping area of BitmapDatas to check for a collision (alpha values >= AlphaTolerance)
		var alphaA:Int = 0;
		var alphaB:Int = 0;
		var idx:Int = 0;
		for (y in 0...overlapHeight) 
		{
			for (x in 0...overlapWidth) 
			{
				idx = (y * overlapWidth + x) << 2;
				alphaA = pixelsA[idx];
				alphaB = pixelsB[idx];
				if (alphaA >= AlphaTolerance && alphaB >= AlphaTolerance) 
				{
					hit = true;
					break; 
				}
			}
			if (hit) break;
		}
		
		if (considerRotation) 
		{
			BMDPool.recycle(testA);
			BMDPool.recycle(testB);
		}
		
		return hit;
	#end
	}
}