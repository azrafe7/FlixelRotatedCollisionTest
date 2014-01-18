package collisions;

import flash.geom.Point;
import flash.geom.Rectangle;


class ForRectangle {
	public static function setTo(r:Rectangle, x:Float, y:Float, w:Float, h:Float):Void 
	{
		r.x = x;
		r.y = y;
		r.width = w;
		r.height = h;
	}
}
