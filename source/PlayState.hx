package; 

import flash.Lib;
import flixel.*;
import flixel.util.*;
import flixel.addons.nape.*;
import nape.dynamics.InteractionGroup;
import nape.geom.Vec2;
import nape.shape.Polygon;
import nape.callbacks.*;
import nape.phys.*;



class PlayState extends FlxNapeState
{	
	public static var CB_Collision:CbType = new CbType();

	private var player1:FlxSprite;
	private var player1collider:FlxNapeSprite;
	private var player2:FlxNapeSprite;
	private var debug:FlxSprite;
	
	private var size:FlxPoint;
	private var collisionDetected:Bool;
	
	override public function create():Void
	{	
		super.create();
		FlxG.camera.bgColor = 0xFFFFBBFF;
		napeDebugEnabled = true;
		size = new FlxPoint(100, 20);
		
		var group:InteractionGroup = new InteractionGroup(false);
		
		player1 = new FlxSprite(100, 100);
		player1.makeGraphic(cast(size.x), cast(size.y));
		player1.setOriginToCenter();
		player1collider = new FlxNapeSprite(100, 100);
		player1collider.makeGraphic(cast(size.x), cast(size.y));
		player1collider.alpha = 0;
		player1collider.createRectangularBody();
		player1collider.body.cbTypes.add(CB_Collision);
		player1collider.body.group = group;
		player1collider.body.shapes.at(0).group = group;
		player1collider.body.shapes.at(0).filter.collisionGroup = 2;
		player1collider.body.shapes.at(0).filter.collisionMask = ~2;
		player1collider.body.shapes.at(0).sensorEnabled = true;
		player1collider.body.type = BodyType.KINEMATIC;
		//player1.setBodyMaterial(0.1, 0.1, 0.1, 0.1);
		
		player2 = new FlxNapeSprite(300, 100);
		player2.makeGraphic(cast(size.x), cast(size.y));
		player2.createRectangularBody();
		player2.body.group = group;
		player2.body.shapes.at(0).group = group;
		player2.body.cbTypes.add(CB_Collision);
		player2.body.shapes.at(0).filter.collisionGroup = 2;
		player2.body.shapes.at(0).filter.collisionMask = ~2;
		player2.body.shapes.at(0).sensorEnabled = true;
		player2.body.type = BodyType.KINEMATIC;
		//player1.setBodyMaterial(0.1, 0.1, 0.1, 0.1);
			
		add(player1);
		add(player1collider);
		add(player2);
		
		FlxNapeState.space.listeners.add(new InteractionListener(CbEvent.BEGIN,
													 InteractionType.SENSOR, 
													 CB_Collision,
													 CB_Collision,
													 onCollisionDetected));
		FlxNapeState.space.listeners.add(new InteractionListener(CbEvent.END,
													 InteractionType.SENSOR, 
													 CB_Collision,
													 CB_Collision,
													 onCollisionUnDetected));
													 
		Lib.trace("loaded!");
	}
	
	function onCollisionDetected(i:InteractionCallback):Void 
	{
		collisionDetected = true;
		Lib.trace("touching");
	}
	
	function onCollisionUnDetected(i:InteractionCallback):Void
	{
		collisionDetected = false;
		Lib.trace("no more touching");
	}
	
	
	override public function update():Void
	{	
		super.update();
		
		
		player1.angle += 1;
		//player2.body.rotation += 0.02;
		
		if (FlxG.keyboard.pressed("LEFT")) player1.x -= 2;
		if (FlxG.keyboard.pressed("RIGHT")) player1.x += 2;
		if (FlxG.keyboard.pressed("UP")) player1.y -= 2;
		if (FlxG.keyboard.pressed("DOWN")) player1.y += 2;
		/*
		if (FlxG.keyboard.pressed("LEFT")) player1.body.position.x -= 2;
		if (FlxG.keyboard.pressed("RIGHT")) player1.body.position.x += 2;
		if (FlxG.keyboard.pressed("UP")) player1.body.position.y -= 2;
		if (FlxG.keyboard.pressed("DOWN")) player1.body.position.y += 2;		
		*/
		if (collisionDetected)
			player2.color = 0xff00ff00;
		else		
			player2.color = 0xff00ffff;
			
	
		player1collider.body.position.setxy(player1.x + player1.origin.x, player1.y + player1.origin.y);
		player1collider.body.rotation = player1.angle * 0.0174532925;
	}	
	
	
}

