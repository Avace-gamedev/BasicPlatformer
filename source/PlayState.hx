package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxTile;
import flixel.util.FlxColor;

class PlayState extends FlxState
{
	var level:TiledLevel;

	public var player:FlxSprite;
	public var exit:FlxSprite;

	var reset_text:FlxText;
	var status:FlxText;
	var status_bg:FlxSprite;

	// jump buffering: if you press jump too early (by at most jump_buffering_delay seconds), you jump anyway once grounded
	var last_jump_cmd:Float = -1;
	var jump_buffering_delay:Float;

	// ledge assist: if you jump too late (by at most ledge_assist_delay seconds) and you're no longer grounded, you jump anyway
	var last_floored_timer:Float = 0;
	var ledge_assist_delay:Float;

	// jump height: you can maintain the jump key to jump higher
	var jump_timer:Float = 0;
	var jump_higher_delay:Float;

	var spike_height:Int = 5; // in pixels, this is used to check if there is an actual overlap with the spikes

	var max_velocity_x:Float;
	var max_velocity_y:Float;

	var jump_velocity:Float;

	var ground_acceleration:Float;
	var air_acceleration:Float;

	var air_drag:Float;
	var moving_drag:Float;
	var stoping_drag:Float;
	var turning_drag:Float;

	override public function new()
	{
		super();
	}

	override public function create()
	{
		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		FlxG.camera.bgColor = 0xFF4169E1;

		super.create();

		// CONFIG

		ledge_assist_delay = 0.05;
		jump_buffering_delay = 0.05;
		jump_higher_delay = 0.1; // at 60 fps this is 6 frames

		max_velocity_x = 600;
		max_velocity_y = 600;

		jump_velocity = 500;

		ground_acceleration = max_velocity_x * 4;
		air_acceleration = max_velocity_x * 2;

		air_drag = max_velocity_x;
		moving_drag = max_velocity_x * 2;
		stoping_drag = max_velocity_x * 100;
		// turning_drag = max_velocity_x * 200;

		// END CONFIG

		player = new FlxSprite(0, 0);
		player.makeGraphic(32, 32, 0xffaa1111);
		player.maxVelocity.x = max_velocity_x;
		player.maxVelocity.y = max_velocity_y;
		player.acceleration.y = 1000;
		FlxG.camera.follow(player);

		level = new TiledLevel(AssetPaths.second__tmx, this);
		add(level.backgroundLayer);
		add(level.imagesLayer);
		add(level.objectsLayer);
		add(level.foregroundTiles);

		// UI

		reset_text = new FlxText(level.tileWidth + 5, 0, 0, "R: reset", 16);
		reset_text.scrollFactor.set(0, 0);
		reset_text.borderColor = 0xff000000;
		reset_text.borderStyle = SHADOW;
		reset_text.alignment = LEFT;
		add(reset_text);

		status = new FlxText(0, 0, 0, "You WON!", 32);
		status.scrollFactor.set(0, 0);
		status.borderColor = 0xff000000;
		status.borderStyle = SHADOW;
		status.alignment = CENTER;
		status.screenCenter();

		status_bg = new FlxSprite();
		status_bg.scrollFactor.set(0, 0);
		status_bg.makeGraphic(Math.floor(status.width + 10), Math.floor(status.height + 10), FlxColor.fromRGBFloat(0, 0, 0, 0.7));
		status_bg.x = status.x - 5;
		status_bg.y = status.y - 5;

		status.visible = false;
		status_bg.visible = false;

		add(status_bg);
		add(status);
	}

	override public function update(elapsed:Float)
	{
		player.acceleration.x = 0;
		player.acceleration.y = 2000; // gravity

		// HORIZONTAL MOVEMENT
		if (FlxG.keys.anyPressed([LEFT, Q]))
		{
			// if (player.velocity.x > 0)
			// 	player.drag.x = turning_drag;

			if (player.isTouching(FlxObject.FLOOR))
				player.acceleration.x -= ground_acceleration;
			else
				player.acceleration.x -= air_acceleration;
		}

		if (FlxG.keys.anyPressed([RIGHT, D]))
		{
			// if (player.velocity.x < 0)
			// 	player.drag.x = turning_drag;

			if (player.isTouching(FlxObject.FLOOR))
				player.acceleration.x += ground_acceleration;
			else
				player.acceleration.x += air_acceleration;
		}

		// VERTICAL MOVEMENT
		if (player.isTouching(FlxObject.FLOOR))
		{
			if (last_floored_timer > 0) // player was in the air before
				if (last_jump_cmd >= 0 && last_jump_cmd < jump_buffering_delay) // and they pressed jump button a little bit early
					jump(elapsed);

			last_floored_timer = 0;
			jump_timer = -1;

			// on floor horizontal drag
			if (FlxG.keys.anyPressed([RIGHT, LEFT, Q, D])) // moving horizontally
				player.drag.x = moving_drag;
			else
				player.drag.x = stoping_drag;
		}
		else // player in the air
		{
			last_floored_timer += elapsed;
			player.drag.x = air_drag;
		}

		if (last_jump_cmd >= 0)
			last_jump_cmd += elapsed;

		if (FlxG.keys.anyPressed([Z, UP, SPACE])) // wants to jump
			if (last_floored_timer < ledge_assist_delay || (jump_timer >= 0 && jump_timer < jump_higher_delay)) // can jump
				jump(elapsed)
			else // cannot, register jump_cmd
				last_jump_cmd = 0;

		if (FlxG.keys.anyJustReleased([Z, UP, SPACE]) && player.velocity.y < 0)
			player.velocity.y *= 0.5;

		super.update(elapsed);

		// collision with white tiles
		level.collideWithGround(player);

		// collision with blue tiles
		level.collideWithDestructible(player);

		// collision with red spikes
		if (level.overlapsWithSpike(player, spike_height))
		{
			trace("DEAD");
			FlxG.resetState();
		}

		if (FlxG.keys.justPressed.R)
			FlxG.resetState();

		FlxG.overlap(exit, player, win);
	}

	function jump(elapsed:Float)
	{
		if (jump_timer < 0 || jump_timer > jump_higher_delay) // button just pressed
		{
			player.velocity.y = 0;
			jump_timer = 0;
		}
		else
			jump_timer += elapsed;

		player.velocity.y -= jump_velocity;
		last_floored_timer = 2 * ledge_assist_delay; // no double jumps
		last_jump_cmd = -1; // reset jump_cmd timer
	}

	public function win(Exit:FlxObject, Player:FlxObject):Void
	{
		status.visible = true;
		status_bg.visible = true;
		player.kill();
	}
}
