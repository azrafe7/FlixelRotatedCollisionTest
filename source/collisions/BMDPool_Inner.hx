package collisions;

import collisions.BMDPool_Inner.ListNode;
import flash.display.BitmapData;
import flash.geom.Rectangle;

using collisions.Extensions;



/**
 * BitmapData pool class.
 * 
 * Notes on implementation:
 *     create() starts searching for a suitable BitmapData from the start of the array
 *     recycle() adds the BitmapData to the start of the array (removing the last one if the array exceeds maxLength)
 * 
 * @author azrafe7
 */
class BMDPool_Inner
{
	private static var _pool:ListNode = null;
	private static var _tail:ListNode = null;
	
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
			var node = _tail;
			while (node != null && _length > value) 
			{
				var bmd = node.bmd;
				bmd.dispose();
				bmd = null;
				node = node.prev;
				_length--;
			}
		}
		return _maxLength = value;
	}
	
	/** Current number of BitmapData present in the pool. */
	public static var length(get, null):Int;
	static function get_length():Int 
	{
		return _length;
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
		var res:BitmapData = null;
		
		var node = _pool;
		while (node != null) {
			var bmd = node.bmd;
			if (bmd.transparent == transparent && bmd.width >= w && bmd.height >= h) {
				if (!exactSize || (exactSize && bmd.width == w && bmd.height == h)) {
					res = bmd;
					if (node.prev != null) node.prev.next = node.next;
					if (node.next != null) node.next.prev = node.prev;
					if (node == _pool) _pool = node.next;
					if (node == _tail) _tail = node.prev;
					node = null;
					_length--;
					break;
				}
			}
			node = node.next;
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
		if (_length >= maxLength) {
			var last = _tail;
			last.bmd.dispose();
			if (last.prev != null) {
				last.prev.next = null;
				_tail = last.prev;
			}
			last = null;
			_length--;
		}
		var node = new ListNode(bmd);
		node.next = _pool;
		if (_pool == null) {
			_pool = _tail = node;
		} else {
			_pool = node;
			node.next.prev = node;
		}
		_length++;
	}
	
	/** Disposes of all the BitmapData in the pool. */
	public static function clear():Void 
	{
		var node = _pool;
		while (node != null) {
			var bmd = node.bmd; 
			bmd.dispose();
			bmd = null;
			node = node.next;
		}
		_length = 0;
	}
}

@:publicFields
class ListNode {
	var bmd:BitmapData = null;
	var prev:ListNode = null;
	var next:ListNode = null;
	
	function new(bmd:BitmapData):Void 
	{
		this.bmd = bmd;
	}
}