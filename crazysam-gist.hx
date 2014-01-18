// https://gist.github.com/crazysam/8304760

	/**
	 * A Pixel Perfect Collision check between two FlxSprites.
	 * It will do a bounds check first, and if that passes it will run a pixel perfect match on the intersecting area.
	 * Works with rotated and animated sprites.
	 * It's extremly slow on cpp targets, so I don't recommend you to use it on them.
	 * Not working on neko target and awfully slows app down
	 * 
	 * @param	Contact			The first FlxSprite to test against
	 * @param	Target			The second FlxSprite to test again, sprite order is irrelevant
	 * @param	AlphaTolerance	The tolerance value above which alpha pixels are included. Default to 255 (must be fully opaque for collision).
	 * @param	Camera			If the collision is taking place in a camera other than FlxG.camera (the default/current) then pass it here
	 * @return	Boolean True if the sprites collide, false if not
	 */
	static public function pixelPerfectCheck(Contact:FlxSprite, Target:FlxSprite, AlphaTolerance:Int = 255, ?Camera:FlxCamera):Bool
	{
		//if either of the angles are non-zero, consider the angles of the sprites in the pixel check
		var considerRotation:Bool = Contact.angle != 0 || Target.angle != 0;
		
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
		
		if (considerRotation)
		{
			// find the center of both sprites
			centerA.set(Contact.origin.x, Contact.origin.y);
			centerB.set(Target.origin.x, Target.origin.y);			
			
			// now make a bounding box that allows for the sprite to be rotated in 360 degrees
			boundsA.set(
				(pointA.x + centerA.x - centerA.length), 
				(pointA.y + centerA.y - centerA.length), 
				centerA.length*2, centerA.length*2);
			boundsB.set(
				(pointB.x + centerB.x - centerB.length), 
				(pointB.y + centerB.y - centerB.length), 
				centerB.length*2, centerB.length*2);			
		}
		else
		{
#if flash
			boundsA.set(pointA.x, pointA.y, Contact.framePixels.width, Contact.framePixels.height);
			boundsB.set(pointB.x, pointB.y, Target.framePixels.width, Target.framePixels.height);
#else
			boundsA.set(pointA.x, pointA.y, Contact.frameWidth, Contact.frameHeight);
			boundsB.set(pointB.x, pointB.y, Target.frameWidth, Target.frameHeight);
#end
		}
		
		var intersect:Rectangle = boundsA.intersection(boundsB);
		
		if (intersect.isEmpty() || intersect.width == 0 || intersect.height == 0)
		{
			return false;
		}
		
		//	Normalise the values or it'll break the BitmapData creation below
		intersect.x = Math.floor(intersect.x);
		intersect.y = Math.floor(intersect.y);
		intersect.width = Math.ceil(intersect.width);
		intersect.height = Math.ceil(intersect.height);
		
		if (intersect.isEmpty())
		{
			return false;
		}
		
		//	Thanks to Chris Underwood for helping with the translate logic :)
		matrixA.identity();
		matrixA.translate(-(intersect.x - boundsA.x), -(intersect.y - boundsA.y));
		
		matrixB.identity();
		matrixB.translate(-(intersect.x - boundsB.x), -(intersect.y - boundsB.y));
		
#if !flash
		Contact.drawFrame(); //@Beeblerox: why is this necessary? - crazysam 1/2014
		Target.drawFrame();  //@Beeblerox: why is this necessary? - crazysam 1/2014
#end
		
		var testA:BitmapData = Contact.framePixels;
		var testB:BitmapData = Target.framePixels;
		
		var imgSize = intersect.width * intersect.height;
		var overlapArea:BitmapData = imgCache.get(imgSize);
		if(overlapArea == null)
		{
			FlxG.log.add("pixelPerfectCollision: New BitmapData, size = " + imgSize);
			overlapArea = new BitmapData(intersect.width, intersect.height, false);
			imgCache.set(imgSize, overlapArea);
		}
		
		// More complicated case, if either of the sprites is rotated
		if (considerRotation)
		{
			testMatrix.identity();
			
			// translate the matrix to the center of the sprite
			testMatrix.translate( -Contact.origin.x, -Contact.origin.y);
			
			// rotate the matrix according to angle
			testMatrix.rotate(Contact.angle * 0.017453293 );  // degrees to rad
			
			// translate it back!
			testMatrix.translate(boundsA.width / 2, boundsA.height / 2);
			
			// prepare an empty canvas
			imgSize = Std.int(boundsA.width) * Std.int(boundsA.height);
			var testA2:BitmapData = imgCache.get(imgSize);
			if(testA2 == null)
			{
				FlxG.log.add("pixelPerfectCollision: New BitmapData, size = " + imgSize);
				testA2 = new BitmapData(Math.floor(boundsA.width) , Math.floor(boundsA.height), true, 0x00000000);
				imgCache.set(imgSize, testA2);
			}
			
			// plot the sprite using the matrix
			testA2.draw(testA, testMatrix, null, null, null, false);
			testA = testA2;
			
			// (same as above)
			testMatrix.identity();
			testMatrix.translate(-Target.origin.x,-Target.origin.y);
			testMatrix.rotate(Target.angle * 0.017453293 );  // degrees to rad
			testMatrix.translate(boundsB.width/2,boundsB.height/2);
			
			imgSize = Math.floor(boundsB.width) * Math.floor(boundsB.height);
			var testB2:BitmapData = imgCache.get(imgSize);
			if(testB2 == null)
			{
				FlxG.log.add("pixelPerfectCollision: New BitmapData, size = " + imgSize);
				testB2 = new BitmapData(Math.floor(boundsB.width), Math.floor(boundsB.height), true, 0x00000000);
				imgCache.set(imgSize, testB2);
			}
			
			testB2.draw(testB, testMatrix, null, null, null, false);			
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