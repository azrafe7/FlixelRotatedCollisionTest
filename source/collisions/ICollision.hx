package collisions;

import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.FlxCamera;

interface ICollision {
	public var debug:BitmapData;
	public function pixelPerfectCheck(Contact:FlxSprite, Target:FlxSprite, AlphaTolerance:Int = 255, ?Camera:FlxCamera):Bool;
}

