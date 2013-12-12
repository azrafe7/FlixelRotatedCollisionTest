package; 

import flixel.*;

class PlayState extends FlxState
{	
	private var player1:FlxSprite;
	private var player2:FlxSprite;
	
	override public function create():Void
	{	
		player1 = new FlxSprite(100, 100);
		player1.makeGraphic(100, 20);
		
		player2 = new FlxSprite(300, 100);
		
		add(player1);
		add(player2);
	}
	
	override public function update():Void
	{	
		player1.angle++;
		player2.angle += 2;
		
		if (FlxG.keyboard.pressed("LEFT")) player1.x -= 2;
		if (FlxG.keyboard.pressed("RIGHT")) player1.x += 2;
		if (FlxG.keyboard.pressed("UP")) player1.y -= 2;
		if (FlxG.keyboard.pressed("DOWN")) player1.y += 2;
		
		if (FlxG.pixelPerfectOverlap(player1, player2))
			player2.makeGraphic(100, 20, 0xff00ff00);
		else		
			player2.makeGraphic(100, 20, 0xff00ffff);
	}	
	
	
}

