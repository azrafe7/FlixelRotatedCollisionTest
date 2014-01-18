// azrafe7 https://github.com/azrafe7/flixel/commit/5f7c2587382c7c3aaedfebe221dc0e0acf95848c

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
		
		var overlapWidth:Int = overlapArea.width;
		var overlapHeight:Int = overlapArea.height;
		
		// non-Flash target quick replacement for Rectangle.setTo()
		inline function setTo(rect:Rectangle, x:Float, y:Float, w:Float, h:Float):Void 
		{
			rect.x = x;
			rect.y = y;
			rect.width = w;
			rect.height = h;
		}
		
		setTo(boundsA, -matrixA.tx, -matrixA.ty, overlapWidth, overlapHeight);
		setTo(boundsB, -matrixB.tx, -matrixB.ty, overlapWidth, overlapHeight);
		var pixelsA = testA.getPixels(boundsA);
		var pixelsB = testB.getPixels(boundsB);
		
		var hit = false;
		
		var alphaA:Int = 0;
		var alphaB:Int = 0;
		var idx:Int = 0;
		for (y in 0...overlapHeight) {
			for (x in 0...overlapWidth) {
				idx = (y * overlapWidth + x) << 2;
				alphaA = pixelsA[idx];
				alphaB = pixelsB[idx];
				if (alphaA >= AlphaTolerance && alphaB >= AlphaTolerance) {
					hit = true;
					break; 
				}
			}
			if (hit) break;
		}
		
		return hit;
		
		#end
		
		// Developers: If you'd like to see how this works enable the debugger and display it in your game somewhere (only Flash target).
		debug = overlapArea;
		
		var overlap:Rectangle = overlapArea.getColorBoundsRect(0xffffffff, 0xff00ffff);
		overlap.offset(intersect.x, intersect.y);
		
		return(!overlap.isEmpty());
	}
