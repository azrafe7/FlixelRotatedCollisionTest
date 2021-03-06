package collisions;

import flash.display.BitmapData;
import flash.geom.Rectangle;

using collisions.Extensions;

/**
 * BitmapData pool class.
 * 
 * Notes on implementation:
 *     create() starts searching for a suitable BitmapData from the start of the array
 *     recycle() adds the BitmapData to the start of the array (removing the last one if the array exceeds maxLength)
 */
class BMDPool
{
	private static var _pool:Array<BitmapData> = new Array<BitmapData>();
	
	private static var _hits:Float = 0.;
	private static var _requests:Float = 0.;
	
	private static var _rect:Rectangle = new Rectangle();
	
	private static var _length:Int = 0;
	private static var _maxLength:Int = 8;
	
	/** Number of BitmapData requests done. */
	public static var requests(get, null):Float;
	static inline function get_requests():Float 
	{
		return _requests;
	}
	
	/** Percentage of times a requested BitmapData was found in the pool. */
	public static var hitRatio(get, null):Float;
	static inline function get_hitRatio():Float 
	{
		return _hits / _requests;
	}
	
	/** Maximum number of BitmapData to hold in the pool. */
	public static var maxLength(get, set):Int;
	static inline function get_maxLength():Int {
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
	
	/** Current number of BitmapData present in the pool. */
	public static var length(get, null):Int;
	static function get_length():Int 
	{
		return _pool.length;
	}
	
	/** 
	 * Returns a BitmapData with the specified parameters. 
	 * If a suitable BitmapData cannot be found in the pool a new one will be created.
	 * If fillColor is specified the returned BitmapData will also be cleared with it.
	 * 
	 * @param ?exactSize	If false a BitmapData with size >= [w, h] may be returned.
	 */
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
			if (fillColor != null) {
				_rect.setTo(0, 0, w, h);
				res.fillRect(_rect, fillColor);
			}
		} else {	// create new one
			res = new BitmapData(w, h, transparent, fillColor != null ? fillColor : 0xFFFFFFFF);
		}
		
		//trace("reqs: " + Std.int(requests) + " hitRatio: " + hitRatio + "   " + length + " in pool");
		return res;
	}
	
	/** Adds bmd to the pool for future use. */
	public static function recycle(bmd:BitmapData):Void 
	{
		if (_pool.length >= maxLength) {
			var last = _pool.pop();
			last.dispose();
			last = null;
		}
		_pool.insert(0, bmd);
	}
	
	/** Disposes of all the BitmapData in the pool. */
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
