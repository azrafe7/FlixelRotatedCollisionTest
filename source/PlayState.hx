package; 

import collisions.BMDPool;
import collisions.DebugCollision;
import collisions.FinalCollision;
import collisions.FinalNoPoolCollision;
import collisions.FinalUnifiedCollision;
import collisions.ICollision;
import collisions.NewCacheCollision;
import collisions.NoCacheCollision;
import collisions.OriginalCollision;
import flash.events.KeyboardEvent;
import flash.system.System;
import flixel.*;
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


class PlayState extends FlxState
{	
	private var nPlayers:Int = 3;
	private var players:Array<FlxSprite> = new Array<FlxSprite>();
	private var player:FlxSprite;
	
	private var bmd:BitmapData = new BitmapData(100, 20);
	
	var switchFunction:Bool = false;
	var dbgPoint:Point;
	var txt:flixel.text.FlxText;
	var INFO1:String = 'R - reset         SPACE - toggle rotation           W/S - num players: ';
	var INFO2:String = 'keys 1-xxx to change collision function             current: ';
	
	private var rotate:Bool = true;
	
	var currentIdx:Int = 0;
	var currentName:String = "";
	var currentFunc:FlxSprite -> FlxSprite -> Int -> ?FlxCamera -> Bool;
	
	var map:Array<{name:String, collision:ICollision}>;
	
	
	public function new(idx:Int = 0, ?rotate:Bool, ?nPlayers:Int) {
		FlxG.log.redirectTraces = false;
		FlxG.game.debugger.log.visible = false;
		FlxG.game.debugger.stats.visible = true;
		
		this.currentIdx = idx;
		if (rotate != null) this.rotate = rotate;
		if (nPlayers != null) this.nPlayers = nPlayers;
		
		super();
	}
	
	public function addPlayer():FlxSprite 
	{
		var p = new FlxSprite(Math.random() * FlxG.camera.width, Math.random() * FlxG.camera.height);
		//p.makeGraphic(100, 20);
		p.loadGraphic(bmd);
		p.angle = Math.random() * 360;
		
		players.push(p);
		add(p);
		
		return p;
	}
	
	override public function create():Void
	{	
		for (i in 0...nPlayers) addPlayer();
		player = players[0];
		player.x = 100;
		player.y = 100;
		
		FlxG.debugger.visible = true;
		dbgPoint = new Point(50, 50);
	
		txt = new FlxText(5, FlxG.camera.height - 26, 400, INFO1 + "\n" + INFO2);
		txt.color = 0x3060E0;
		add(txt);
		
		map = new Array();
		map.push({name:"original (unmodified)", collision:new OriginalCollision()});
		map.push({name:"opt no-cache (bad)", collision:new NoCacheCollision()});
		map.push({name:"opt pool (bad)", collision:new NewCacheCollision()});
		map.push({name:"opt debug", collision:new DebugCollision()});
		map.push({name:"final (w/ pool)", collision:new FinalCollision()});
		map.push({name:"final (no pool)", collision:new FinalNoPoolCollision()});
		map.push({name:"unified (w/ pool)", collision:new FinalUnifiedCollision()});
		
		INFO2 = INFO2.split("xxx").join(Std.string(map.length));
		updateInfo();
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}
	
	override public function update():Void
	{			
		if (switchFunction) {
			updateInfo();
			switchFunction = false;
		}
		
		if (FlxG.keyboard.pressed("LEFT")) player.x -= 2;
		if (FlxG.keyboard.pressed("RIGHT")) player.x += 2;
		if (FlxG.keyboard.pressed("UP")) player.y -= 2;
		if (FlxG.keyboard.pressed("DOWN")) player.y += 2;
	
		if (FlxG.keyboard.pressed("ESCAPE")) {
		#if (flash || js)
			System.exit(0);
		#else
			Sys.exit(0);
		#end
		}
		
		if (FlxG.keyboard.justPressed("SPACE")) rotate = !rotate;
		if (FlxG.keyboard.justPressed("R")) FlxG.switchState(new PlayState(currentIdx, rotate, nPlayers));
	
		if (FlxG.keyboard.justPressed("W", "Z")) nPlayers++;
		if (FlxG.keyboard.justPressed("S")) nPlayers = Std.int(Math.max(nPlayers - 1, 2));
		
		// add/remove players
		if (nPlayers != players.length) {
			var len = players.length;
			if (nPlayers > len) addPlayer();
			else remove(players.pop());
			
			updateInfo();
		}
		
		// update rotation
		if (rotate) {
			for (i in 0...players.length) {
				var p1 = players[i];
				p1.angle += (i == 0) ? 1 : 2;
			}
		}
		
		// (naive) pixel perfect check between all
		for (i in 0...players.length) {
			var p1 = players[i];
			var collides = false;
			for (j in 0...players.length) {
				if (i == j) continue;
				
				var p2 = players[j];
				if (currentFunc(p1, p2, 255)) {
					collides = true;
					break;
				}
			}
			p1.color = collides ? 0x00FF00 : 0xFFFFFF;
		}
	}	
	
	override public function draw():Void 
	{
		super.draw();
	#if (flash || js)
		//FlxG.camera.buffer.copyPixels(map[currentIdx].collision.debug, map[currentIdx].collision.debug.rect, dbgPoint);
	#end
	}
	
	public function updateInfo():Void 
	{
		currentFunc = map[currentIdx].collision.pixelPerfectCheck;
		currentName = map[currentIdx].name;
		txt.text = INFO1 + nPlayers + "\n" + INFO2 + (currentIdx + 1) + " - " + currentName;
	}
	
	// switch collision func on keypress
	public function onKeyUp(e:KeyboardEvent):Void 
	{
		if (e.keyCode >= "1".code && e.keyCode < ("1".code + map.length)) {
			if (currentIdx != e.keyCode - "1".code) {
				currentIdx = e.keyCode - "1".code;
				switchFunction = true;
			};
		}
	}
}
