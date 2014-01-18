package collisions;

// original 

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
import flixel.util.FlxColor;


using collisions.Extensions;	// temp workaround to have Rectangle.setTo() on all targets


class OriginalCollision implements ICollision {
	public var debug:BitmapData = new BitmapData(1, 1, false);

	public function new():Void 
	{
		
	}
	
	/**
	 * A Pixel Perfect Collision check between two FlxSprites.
	 * It will do a bounds check first, and if that passes it will run a pixel perfect match on the intersecting area.
	 * Works with rotated and animated sprites.
	 * It's extremly slow on cpp targets, so I don't recommend you to use it on them.
	 * Not working on neko target and awfully slows app down
	 * 
	 * @param        Contact                        The first FlxSprite to test against
	 * @param        Target                        The second FlxSprite to test again, sprite order is irrelevant
	 * @param        AlphaTolerance        The tolerance value above which alpha pixels are included. Default to 255 (must be fully opaque for collision).
	 * @param        Camera                        If the collision is taking place in a camera other than FlxG.camera (the default/current) then pass it here
	 * @return        Boolean True if the sprites collide, false if not
	 */
	public function pixelPerfectCheck(Contact:FlxSprite, Target:FlxSprite, AlphaTolerance:Int = 255, ?Camera:FlxCamera):Bool
	{
		//if either of the angles are non-zero, consider the angles of the sprites in the pixel check
		var considerRotation:Bool = Contact.angle != 0 || Target.angle != 0;
		
		var pointA:Point = new Point();
		var pointB:Point = new Point();
		
		if (Camera != null)
		{
				pointA.x = Contact.x - Std.int(Camera.scroll.x * Contact.scrollFactor.x) - Contact.offset.x;
				pointA.y = Contact.y - Std.int(Camera.scroll.y * Contact.scrollFactor.y) - Contact.offset.y;
				
				pointB.x = Target.x - Std.int(Camera.scroll.x * Target.scrollFactor.x) - Target.offset.x;
				pointB.y = Target.y - Std.int(Camera.scroll.y * Target.scrollFactor.y) - Target.offset.y;
		}
		else
		{
				pointA.x = Contact.x - Std.int(FlxG.camera.scroll.x * Contact.scrollFactor.x) - Contact.offset.x;
				pointA.y = Contact.y - Std.int(FlxG.camera.scroll.y * Contact.scrollFactor.y) - Contact.offset.y;
				
				pointB.x = Target.x - Std.int(FlxG.camera.scroll.x * Target.scrollFactor.x) - Target.offset.x;
				pointB.y = Target.y - Std.int(FlxG.camera.scroll.y * Target.scrollFactor.y) - Target.offset.y;
		}
		
		var boundsA:Rectangle = null;
		var boundsB:Rectangle = null;
		if (considerRotation)
		{
				// find the center of both sprites
				var centerA:Point = new Point(Contact.origin.x, Contact.origin.y);
				var centerB:Point = new Point(Target.origin.x, Target.origin.y);                        
				
				// now make a bounding box that allows for the sprite to be rotated in 360 degrees
				boundsA = new Rectangle(
						(pointA.x + centerA.x - centerA.length), 
						(pointA.y + centerA.y - centerA.length), 
						centerA.length*2, centerA.length*2);
				boundsB = new Rectangle(
						(pointB.x + centerB.x - centerB.length), 
						(pointB.y + centerB.y - centerB.length), 
						centerB.length*2, centerB.length*2);                        
		}
		else
		{
				#if flash
				boundsA = new Rectangle(pointA.x, pointA.y, Contact.framePixels.width, Contact.framePixels.height);
				boundsB = new Rectangle(pointB.x, pointB.y, Target.framePixels.width, Target.framePixels.height);
				#else
				boundsA = new Rectangle(pointA.x, pointA.y, Contact.frameWidth, Contact.frameHeight);
				boundsB = new Rectangle(pointB.x, pointB.y, Target.frameWidth, Target.frameHeight);
				#end
		}
		
		var intersect:Rectangle = boundsA.intersection(boundsB);
		
		if (intersect.isEmpty() || intersect.width == 0 || intersect.height == 0)
		{
				return false;
		}
		
		//        Normalise the values or it'll break the BitmapData creation below
		intersect.x = Math.floor(intersect.x);
		intersect.y = Math.floor(intersect.y);
		intersect.width = Math.ceil(intersect.width);
		intersect.height = Math.ceil(intersect.height);
		
		if (intersect.isEmpty())
		{
				return false;
		}
		
		//        Thanks to Chris Underwood for helping with the translate logic :)
		var matrixA:Matrix = new Matrix();
		matrixA.translate(-(intersect.x - boundsA.x), -(intersect.y - boundsA.y));
		
		var matrixB:Matrix = new Matrix();
		matrixB.translate(-(intersect.x - boundsB.x), -(intersect.y - boundsB.y));
		
		#if !flash
		Contact.drawFrame();
		Target.drawFrame();
		#end
		
		var testA:BitmapData = Contact.framePixels;
		var testB:BitmapData = Target.framePixels;
		var overlapArea:BitmapData = new BitmapData(Std.int(intersect.width), Std.int(intersect.height), false);
		
		// More complicated case, if either of the sprites is rotated
		if (considerRotation)
		{
				var testAMatrix:Matrix = new Matrix();
				testAMatrix.identity();
				
				// translate the matrix to the center of the sprite
				testAMatrix.translate( -Contact.origin.x, -Contact.origin.y);
				
				// rotate the matrix according to angle
				testAMatrix.rotate(Contact.angle * 0.017453293 );  // degrees to rad
				
				// translate it back!
				testAMatrix.translate(boundsA.width / 2, boundsA.height / 2);
				
				// prepare an empty canvas
				var testA2:BitmapData = new BitmapData(Math.floor(boundsA.width) , Math.floor(boundsA.height), true, 0x00000000);
				
				// plot the sprite using the matrix
				testA2.draw(testA, testAMatrix, null, null, null, false);
				testA = testA2;
				
				// (same as above)
				var testBMatrix:Matrix = new Matrix();
				testBMatrix.identity();
				testBMatrix.translate(-Target.origin.x,-Target.origin.y);
				testBMatrix.rotate(Target.angle * 0.017453293 );  // degrees to rad
				testBMatrix.translate(boundsB.width/2,boundsB.height/2);
				var testB2:BitmapData = new BitmapData(Math.floor(boundsB.width), Math.floor(boundsB.height), true, 0x00000000);
				testB2.draw(testB, testBMatrix, null, null, null, false);                        
				testB = testB2;
		}
		
		
		#if flash
		overlapArea.draw(testA, matrixA, new ColorTransform(1, 1, 1, 1, 255, -255, -255, AlphaTolerance), BlendMode.NORMAL);
		overlapArea.draw(testB, matrixB, new ColorTransform(1, 1, 1, 1, 255, 255, 255, AlphaTolerance), BlendMode.DIFFERENCE);
		#else
		
		// TODO: try to fix this method for neko target
		var overlapWidth:Int = overlapArea.width;
		var overlapHeight:Int = overlapArea.height;
		var targetX:Int;
		var targetY:Int;
		var pixelColor:Int;
		var pixelAlpha:Int;
		var transformedAlpha:Int;
		var maxX:Int = testA.width + 1;
		var maxY:Int = testA.height + 1;
		
		for (i in 0...maxX)
		{
				targetX = Math.floor(i + matrixA.tx);
				
				if (targetX >= 0 && targetX < maxX)
				{
						for (j in 0...maxY)
						{
								targetY = Math.floor(j + matrixA.ty);
								
								if (targetY >= 0 && targetY < maxY)
								{
										pixelColor = testA.getPixel32(i, j);
										pixelAlpha = (pixelColor >> 24) & 0xFF;
										
										if (pixelAlpha >= AlphaTolerance)
										{
												overlapArea.setPixel32(targetX, targetY, 0xffff0000);
										}
										else
										{
												overlapArea.setPixel32(targetX, targetY, FlxColor.WHITE);
										}
								}
						}
				}
		}

		maxX = testB.width + 1;
		maxY = testB.height + 1;
		var secondColor:Int;
		
		for (i in 0...maxX)
		{
				targetX = Math.floor(i + matrixB.tx);
				
				if (targetX >= 0 && targetX < maxX)
				{
						for (j in 0...maxY)
						{
								targetY = Math.floor(j + matrixB.ty);
								
								if (targetY >= 0 && targetY < maxY)
								{
										pixelColor = testB.getPixel32(i, j);
										pixelAlpha = (pixelColor >> 24) & 0xFF;
										
										if (pixelAlpha >= AlphaTolerance)
										{
												secondColor = overlapArea.getPixel32(targetX, targetY);
												
												if (secondColor == 0xffff0000)
												{
														overlapArea.setPixel32(targetX, targetY, 0xff00ffff);
												}
												else
												{
														overlapArea.setPixel32(targetX, targetY, 0x00000000);
												}
										}
								}
						}
				}
		}
		
		#end
		
		// Developers: If you'd like to see how this works enable the debugger and display it in your game somewhere.
		debug = overlapArea;
		
		var overlap:Rectangle = overlapArea.getColorBoundsRect(0xffffffff, 0xff00ffff);
		overlap.offset(intersect.x, intersect.y);
		
		return(!overlap.isEmpty());
	}	
}