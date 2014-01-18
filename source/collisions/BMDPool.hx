package collisions;

import flash.display.BitmapData;
import flash.geom.Rectangle;

using collisions.Extensions;


class BMDPool
{
	private static var _hits:Float = 0.;
	private static var _requests:Float = 0.;
	
	public static var requests(get, null):Float;
	static function get_requests():Float 
	{
		return _requests;
	}
	
	public static var hitRatio(get, null):Float;
	static function get_hitRatio():Float 
	{
		return _hits / _requests;
	}
	
	private static var _rect:Rectangle = new Rectangle();
	
	private static var _length:Int = 0;
	private static var _maxLength:Int = 8;
	
	private static var _pool:Array<BitmapData> = new Array<BitmapData>();
	
	public static var decay(default, default):Int;
	
	public static var maxLength(get, set):Int;
	static function get_maxLength():Int {
		return _maxLength;
	}
	static function set_maxLength(value:Int):Int 
	{
		if (_maxLength != value) {
			if (_pool.length > value) {
				for (i in value..._pool.length) {
					var bmd = _pool[i];
					bmd.dispose();
					bmd = null;
				}
			#if !(cpp || php)
				untyped _pool.length = value;
			#else
				_pool.splice(value, _pool.length);
			#end
			}
		}
		return _maxLength = value;
	}
	
	public static var length(get, null):Int;
	static function get_length():Int 
	{
		return _pool.length;
	}
	
	public static function create(w:Int, h:Int, transparent:Bool = true, ?fillColor:Int, ?exactSize:Bool = false):BitmapData 
	{
		_requests += 1.;
		var idx = -1;
		var res:BitmapData = null;
		
		for (i in 0..._pool.length) {
			var bmd = _pool[i];
			if (bmd.transparent == transparent && bmd.width >= w && bmd.height >= h) {
				if (!exactSize || (exactSize && bmd.width == w && bmd.height == h)) {
					res = bmd;
					_pool.splice(i, 1);
					idx = i;
					break;
				}
			}
		}
		
		if (res != null) {	// found one in pool
			_hits += 1.;
			//trace("hit : " + (_hits) + " / " + _requests + ' req: ${w}x${h} t:$transparent ex:$exactSize @$idx');
			if (fillColor != null) {
				_rect.setTo(0, 0, w, h);
				res.fillRect(_rect, fillColor);
			}
		} else {	// create new one
			//trace("miss: " + (_requests-_hits) + " / " + _requests + ' req: ${w}x${h} t:$transparent ex:$exactSize @$idx');
			res = new BitmapData(w, h, transparent, fillColor != null ? fillColor : 0xFFFFFFFF);
		}
		
		//trace("reqs: " + Std.int(requests) + " hitRatio: " + hitRatio + "   " length + " in pool");
		return res;
	}
	
	public static function recycle(bmd:BitmapData):Void 
	{
		if (_pool.length >= maxLength) {
			var last = _pool.pop();
			last.dispose();
			last = null;
		}
		_pool.insert(0, bmd);
	}
	
	public static function clear():Void 
	{
		for (bmd in _pool) {
			bmd.dispose();
			bmd = null;
		}
	#if !(cpp || php)
		untyped _pool.length = 0;
	#else
		_pool.splice(0, _pool.length);
	#end
	}
}
