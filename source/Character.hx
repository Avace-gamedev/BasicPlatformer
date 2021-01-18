import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

class Character extends FlxSprite
{
	// jump buffering: if you press jump too early (by at most jump_buffering_delay seconds), you jump anyway once grounded
	var last_jump_cmd:Float = -1;
	var jump_buffering_delay:Float;

	// ledge assist: if you jump too late (by at most ledge_assist_delay seconds) and you're no longer grounded, you jump anyway
	var last_floored_timer:Float = 0;
	var ledge_assist_delay:Float;

	// jump height: you can maintain the jump key to jump higher
	var jump_timer:Float = -1;
	var jump_higher_delay:Float;

	var jump_btn_released:Bool = true;
	var can_jump(get, never):Bool;

	var jump_velocity:Float;

	var ground_acceleration:Float;
	var air_acceleration:Float;

	var air_drag:Float;
	var moving_drag:Float;
	var stoping_drag:Float;
	var turning_drag:Float;
	var wall_drag:Float;

	override public function new()
	{
		super();

		loadGraphic(AssetPaths.character__png, true, 32, 32);
		animation.add("stand", [0, 1], 2, true);
		animation.add("jump", [5, 6, 7, 8, 9], 10, false);
		animation.add("landing", [6, 5], 10, false);
		animation.play("stand");

		height = 28;
		width = 26;
		offset.set(3, 4);

		// CONFIG

		ledge_assist_delay = 0.05;
		jump_buffering_delay = 0.05;
		jump_higher_delay = 0.1; // at 60 fps this is 6 frames

		maxVelocity.x = 600;
		maxVelocity.y = 600;
		jump_velocity = 500;

		ground_acceleration = maxVelocity.x * 4;
		air_acceleration = maxVelocity.x * 2;

		air_drag = maxVelocity.x;
		moving_drag = maxVelocity.x * 2;
		stoping_drag = maxVelocity.x * 10;
		turning_drag = maxVelocity.x * 50;
		wall_drag = maxVelocity.y * 50;
	}

	function get_can_jump()
	{
		//    player hit jump a little bit early before touching ground
		// OR player is hitting jump and is on ground
		// OR player is hitting jump and is a little bit too late after leaving ground
		return (isTouching(FlxObject.FLOOR) && (last_floored_timer > 0 || (last_jump_cmd >= 0 && last_jump_cmd < jump_buffering_delay)))
			|| (jump_timer >= 0 && jump_timer < jump_higher_delay)
			|| (jump_btn_released && FlxG.keys.anyPressed([Z, UP, SPACE]) && (isTouching(FlxObject.FLOOR) // on floor
				|| isTouching(FlxObject.LEFT) // on a wall (left)
				|| isTouching(FlxObject.RIGHT) // on a wall (right)
				|| last_floored_timer < ledge_assist_delay // little late
			));
	}

	override public function update(elapsed:Float)
	{
		acceleration.x = 0;
		acceleration.y = 2000; // gravity

		// VERTICAL MOVEMENT
		if (isTouching(FlxObject.FLOOR))
		{
			if (animation.finished)
				animation.play("stand");

			last_floored_timer = 0;
			jump_timer = -1;

			// on floor horizontal drag
			if (FlxG.keys.anyPressed([RIGHT, LEFT, Q, D])) // moving horizontally
				drag.x = moving_drag;
			else
				drag.x = stoping_drag;
		}
		else if (isTouching(FlxObject.LEFT) || isTouching(FlxObject.RIGHT))
		{
			drag.y = wall_drag;
			trace("WAAAAALL");
		}
		else // player in the air
		{
			last_floored_timer += elapsed;
			drag.x = air_drag;
			drag.y = 0;
		}

		if (last_jump_cmd >= 0)
			last_jump_cmd += elapsed;

		if (can_jump)
			jump(elapsed)
		else if (FlxG.keys.anyJustPressed([Z, UP, SPACE]))
			last_jump_cmd = 0; // start timer (jump buffering)
		else if (FlxG.keys.anyJustReleased([Z, UP, SPACE]))
			jump_btn_released = true;

		if (FlxG.keys.anyJustReleased([Z, UP, SPACE]) && velocity.y < 0)
		{
			velocity.y *= 0.5;
			jump_timer = -1;
		}

		// HORIZONTAL MOVEMENT
		if (FlxG.keys.anyPressed([LEFT, Q]))
		{
			if (velocity.x > 0)
				drag.x = turning_drag;

			if (isTouching(FlxObject.FLOOR))
				acceleration.x -= ground_acceleration;
			else
				acceleration.x -= air_acceleration;
		}

		if (FlxG.keys.anyPressed([RIGHT, D]))
		{
			if (velocity.x < 0)
				drag.x = turning_drag;

			if (isTouching(FlxObject.FLOOR))
				acceleration.x += ground_acceleration;
			else
				acceleration.x += air_acceleration;
		}

		super.update(elapsed);
	}

	function jump(elapsed:Float)
	{
		if (jump_timer < 0 || jump_timer > jump_higher_delay) // button was not pressed before
		{
			velocity.y = 0;
			jump_timer = 0;
			animation.play("jump");

			if (isTouching(FlxObject.LEFT)) // wall jump to right
			{
				velocity.x += Math.sqrt(2) * jump_velocity;
				velocity.y -= Math.sqrt(2) * jump_velocity;
			}
			else if (isTouching(FlxObject.RIGHT)) // wall jump to left
			{
				velocity.x -= Math.sqrt(2) * jump_velocity;
				velocity.y -= Math.sqrt(2) * jump_velocity;
			}
			else
				velocity.y -= jump_velocity; // after initial impulse, always jump up
		}
		else
		{
			jump_timer += elapsed;
			velocity.y -= jump_velocity; // after initial impulse, always jump up
		}

		jump_btn_released = false;
		last_floored_timer = 2 * ledge_assist_delay; // no double jumps
		last_jump_cmd = -1; // reset jump_cmd timer
	}
}
