package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;

class PlayState extends FlxState
{
	var level:TiledLevel;

	public var player:FlxSprite;
	public var floor:FlxObject;
	public var exit:FlxSprite;

	var jumping = false;
	var jump_time:Float = 0;
	var max_jump_time:Float = 0.2;

	var ground_max_velocity_x = 600;
	var air_max_velocity_x = 400;

	override public function new()
	{
		super();
	}

	override public function create()
	{
		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		FlxG.camera.bgColor = 0xFF00070D;

		super.create();

		player = new FlxSprite(0, 0);
		player.makeGraphic(32, 32, 0xffaa1111);
		player.maxVelocity.y = 600;
		player.acceleration.y = 1000;
		player.drag.x = player.maxVelocity.x * 4;
		FlxG.camera.follow(player);

		level = new TiledLevel(AssetPaths.first__tmx, this);
		add(level.backgroundLayer);
		add(level.imagesLayer);
		add(level.objectsLayer);
		add(level.foregroundTiles);
	}

	override public function update(elapsed:Float)
	{
		player.acceleration.x = 0;
		player.acceleration.y = 2000; // gravity

		if (player.isTouching(FlxObject.FLOOR))
			player.maxVelocity.x = ground_max_velocity_x;
		else
			player.maxVelocity.x = air_max_velocity_x;

		if (jumping)
		{
			jump_time += elapsed;
			player.velocity.y = -player.maxVelocity.y * Math.exp(jump_time / max_jump_time);
		}
		if (jump_time >= max_jump_time)
		{
			jumping = false;
			jump_time = 0;
			player.velocity.y = -player.maxVelocity.y;
		}

		if (FlxG.keys.anyPressed([LEFT, Q]))
			if (player.isTouching(FlxObject.FLOOR))
				player.acceleration.x -= ground_max_velocity_x * 4 + (player.velocity.x > 0 ? ground_max_velocity_x * 4 * 0.5 : 0);
			else
				player.acceleration.x -= air_max_velocity_x * 4 + (player.velocity.x > 0 ? air_max_velocity_x * 4 * 0.5 : 0);

		if (FlxG.keys.anyPressed([RIGHT, D]))
			if (player.isTouching(FlxObject.FLOOR))
				player.acceleration.x += ground_max_velocity_x * 4 + (player.velocity.x < 0 ? ground_max_velocity_x * 4 * 0.5 : 0);
			else
				player.acceleration.x += air_max_velocity_x * 4 + (player.velocity.x < 0 ? air_max_velocity_x * 4 * 0.5 : 0);

		if (FlxG.keys.anyPressed([Z, UP, SPACE]) && player.isTouching(FlxObject.FLOOR))
		{
			jumping = true;
			jump_time = 0;
		}
		if (FlxG.keys.anyJustReleased([Z, UP, SPACE]))
		{
			jumping = false;
			jump_time = 0;
		}

		super.update(elapsed);

		level.collideWithLevel(player);

		FlxG.overlap(exit, player, win);

		if (FlxG.overlap(player, floor))
		{
			FlxG.resetState();
		}
	}

	public function win(Exit:FlxObject, Player:FlxObject):Void
	{
		player.kill();
	}
}
