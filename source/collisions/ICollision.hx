package collisions;

import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.FlxCamera;

typedef IBMDPool = {
	function create(w:Int, h:Int, transparent:Bool, ?fillColor:Null<Int>, ?exactSize:Null<Bool>):BitmapData;
	function recycle(bmd:BitmapData):Void;
	var hitRatio(get, null):Float;
}


interface ICollision {
	public var debug:BitmapData;
	public function pixelPerfectCheck(Contact:FlxSprite, Target:FlxSprite, AlphaTolerance:Int = 255, ?Camera:FlxCamera):Bool;
}

class BMDPool {
	public static var inst:IBMDPool = BMDPool_Array;
}