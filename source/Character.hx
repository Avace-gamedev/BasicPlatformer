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

	var wall_stick_timer:Float = -1;
	var wall_stick_delay:Float = 0.3;
	var touching_left_wall:Bool = true;

	var jump_btn_released:Bool = true;
	var can_jump(get, never):Bool;

	public var double_jump_unlocked = false;

	var double_jump = false;

	var max_velocity_y = 600;
	var jump_velocity:Float;

	var ground_acceleration:Float;
	var air_acceleration:Float;

	var air_drag:Float;
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
		animation.add("grab_left", [10], 2, true);
		animation.add("grab_right", [10], 2, true, true, false);
		animation.play("stand");

		height = 28;
		width = 28;
		offset.set(2, 4);

		// CONFIG

		ledge_assist_delay = 0.05;
		jump_buffering_delay = 0.05;
		jump_higher_delay = 0.1; // at 60 fps this is 6 frames

		maxVelocity.x = 600;
		maxVelocity.y = max_velocity_y;
		jump_velocity = 500;

		ground_acceleration = maxVelocity.x * 4;
		air_acceleration = maxVelocity.x * 2;

		air_drag = maxVelocity.x;
		stoping_drag = maxVelocity.x * 10;
		turning_drag = maxVelocity.x * 50;
		wall_drag = maxVelocity.y * 5000;
	}

	function get_can_jump()
	{
		//    player hit jump a little bit early before touching ground
		// OR player is hitting jump and is on ground
		// OR player is hitting jump and is a little bit too late after leaving ground
		return (isTouching(FlxObject.FLOOR) && (last_floored_timer > 0 || (last_jump_cmd >= 0 && last_jump_cmd < jump_buffering_delay)))
			|| (jump_timer >= 0 && jump_timer < jump_higher_delay)
			|| (jump_btn_released && FlxG.keys.anyPressed([Z, UP, SPACE]) && ((isTouching(FlxObject.FLOOR) // on floor
				|| (double_jump_unlocked && !double_jump)) || wall_stick_timer >= 0 // stuck on a wall
				|| last_floored_timer < ledge_assist_delay // little late
			));
	}

	override public function update(elapsed:Float)
	{
		acceleration.x = 0;
		acceleration.y = 2000; // gravity
		maxVelocity.y = max_velocity_y;

		// update timers
		if (wall_stick_timer >= 0)
			wall_stick_timer += elapsed;
		if (last_jump_cmd >= 0)
			last_jump_cmd += elapsed;

		// VERTICAL MOVEMENT

		if (isTouching(FlxObject.FLOOR))
		{
			if (last_floored_timer > 0) // was in the air before
			{
				Content.sound_land.play();
				animation.play("landing");
			}

			if (animation.finished || wall_stick_timer >= 0)
				animation.play("stand");

			last_floored_timer = 0;
			jump_timer = -1;
			double_jump = false;

			drag.x = stoping_drag;

			wall_stick_timer = -1;
		}
		else if (isTouching(FlxObject.LEFT) || isTouching(FlxObject.RIGHT) || wall_stick_timer >= 0)
		{
			// WALL STICK

			if (wall_stick_timer < 0)
			{
				wall_stick_timer = 0;
				acceleration.y -= 1500;
				touching_left_wall = isTouching(FlxObject.LEFT);
				if (touching_left_wall)
					animation.play("grab_left");
				else
					animation.play("grab_right");
			}
			else if (wall_stick_timer > wall_stick_delay)
			{
				wall_stick_timer = -1;
				animation.play("stand");
			}
			acceleration.y -= 1800;
			maxVelocity.y = max_velocity_y / 10;
			double_jump = false;

			if (velocity.y < 0)
				velocity.y = 0;
		}
		else // player in the air
		{
			last_floored_timer += elapsed;
			drag.x = air_drag;
			wall_stick_timer = -1;
			animation.play("stand");
		}

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
		// don't take into account if stuck to wall
		if (wall_stick_timer < 0 || wall_stick_timer > wall_stick_delay)
		{
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
			Content.sound_jump.play();

			if (!isTouching(FlxObject.FLOOR) && wall_stick_timer < 0)
				double_jump = true;

			if (wall_stick_timer >= 0) // wall jump to right
			{
				if (touching_left_wall)
					velocity.x += Math.sqrt(2) * jump_velocity;
				else
					velocity.x -= Math.sqrt(2) * jump_velocity;
				velocity.y -= Math.sqrt(2) * jump_velocity;

				wall_stick_timer = -1;
			}
			else
				velocity.y -= jump_velocity; // after initial impulse, always jump up
		}
		else
		{
			if (wall_stick_timer < 0)
			{
				jump_timer += elapsed;
				velocity.y -= jump_velocity;
			}
			else
				jump_timer = -1;
		}

		jump_btn_released = false;
		last_floored_timer = 2 * ledge_assist_delay; // no double jumps
		last_jump_cmd = -1; // reset jump_cmd timer
	}
}
