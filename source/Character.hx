import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Character extends FlxSprite
{
	public var double_jump_unlocked = false;

	var max_velocity_y = 600;
	var jump_velocity:Float;

	var ground_acceleration:Float;
	var air_acceleration:Float;

	var air_drag:Float;
	var stoping_drag:Float;
	var turning_drag:Float;
	var wall_drag:Float;

	var state_machine:StateMachine;

	override public function new(double_jump_unlocked = false)
	{
		super();

		this.double_jump_unlocked = double_jump_unlocked;
		state_machine = new StateMachine(this);

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

		scale.set(0, 0);
		FlxTween.tween(this, {"scale.x": 1, "scale.y": 1}, 0.5, {ease: FlxEase.quadOut, type: ONESHOT});

		// CONFIG

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

	override public function update(elapsed:Float)
	{
		acceleration.x = 0;
		acceleration.y = 2000; // gravity
		maxVelocity.y = max_velocity_y;

		var init = state_machine.init;

		state_machine.update(elapsed);

		switch (state_machine.state)
		{
			case GROUND:
				if (init)
				{
					// first frame of the state
					Content.sound_land.play();

					switch (state_machine.last_state)
					{
						case AIR(_):
							animation.play("landing");
						default:
					}
				}

				switch (state_machine.last_state)
				{
					case AIR(_):
						if (animation.finished) animation.play("stand");
					case WALL(_):
						animation.play("stand");
					default:
				}

				drag.x = stoping_drag; // we can set this at every frame because it's only taken into account when acceleration is 0
			case AIR(_):
				if (init)
					if (state_machine.did_jump)
						animation.play("jump");
					else
						animation.play("stand");

				drag.x = air_drag;

				if (animation.finished)
					animation.play("stand");
			case WALL(left):
				acceleration.y *= 0.25;
				maxVelocity.y = max_velocity_y / 10;
				if (velocity.y < 0)
					velocity.y = 0;

				if (left)
					animation.play("grab_left");
				else
					animation.play("grab_right");
		}

		// HORIZONTAL MOVEMENT
		// don't take into account if stuck to wall
		switch (state_machine.state)
		{
			case WALL(_):
			default:
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

	public function jump(elapsed:Float, wall:Bool = false, wall_left:Bool = false)
	{
		if (wall)
		{
			if (wall_left)
				velocity.x += Math.sqrt(2) * jump_velocity;
			else
				velocity.x -= Math.sqrt(2) * jump_velocity;
			velocity.y -= Math.sqrt(2) * jump_velocity;
		}
		else
			velocity.y -= jump_velocity; // after initial impulse, always jump up
	}

	public function continue_jump(elapsed:Float)
		velocity.y -= jump_velocity;
}

enum MachineState
{
	GROUND;
	AIR(n_jumps:Int);
	WALL(left:Bool);
}

class StateMachine
{
	var character:Character;

	// PARAMETERS
	var max_n_jumps:Int = 2;
	var hold_jump_delay:Float = 0.1;
	var jump_buffer_delay:Float = 0.05;
	var ledge_assist_delay:Float = 0.05;
	var stick_wall_delay:Float = 0.3;

	// ---- END PARAMETERS
	var memory = {
		// timers
		hold_jump_timer: -1.0,
		jump_buffer_timer: -1.0,
		ledge_assist_timer: -1.0,
		stick_wall_timer: -1.0,
		//
		init: true,
		last_state: AIR(1),
		did_jump: false,
	};

	public var state(default, null):MachineState;
	public var init(get, never):Bool;
	public var did_jump(get, never):Bool;
	public var last_state(get, never):MachineState;

	public function new(character:Character)
	{
		this.character = character;
		memory.last_state = AIR(1);
		state = AIR(1);

		if (character.double_jump_unlocked)
			max_n_jumps = 2;
		else
			max_n_jumps = 1;
	}

	public function get_init()
		return memory.init;

	public function get_did_jump()
		return memory.did_jump;

	public function get_last_state()
		return memory.last_state;

	/*
	 * automaton:
	 * 	- states: GROUND, AIR(n_jumps), WALL
	 * 	- transitions:
	 * 		- falling: GROUND -> AIR(0)
	 * 			ledge_assist_timer > ledge_assist delay
	 * 			/ reset ledge_assist_timer
	 * 		- jump: GROUND -> AIR(0)
	 * 			justpressed jump key
	 * 		- double_jump: AIR(n) -> AIR(n+1)
	 * 			justpressed jump key
	 * 		and n+1 < max_n_jumps
	 * 		- buffered_jump: AIR(n) -> AIR(0)
	 * 			touching_ground
	 * 		and jump_buffer_timer >= 0 && jump_buffer_timer <= jump_buffer_delay
	 * 			/ reset jump_buffer_timer
	 * 		- land: AIR(n) -> GROUND
	 * 			touching_ground
	 * 		- stick: AIR(n) -> WALL
	 * 			touching_wall
	 * 			/ reset stick_wall_timer
	 * 		- unstick: WALL -> AIR(0)
	 * 			justpressed jump key
	 * 		 or stick_wall_timer > stick_wall_delay
	 * 		- land_from_wall: WALL -> GROUND
	 * 			touching_ground
	 */
	public function update(elapsed:Float)
	{
		// READ MEMORY

		var just_jumped = FlxG.keys.anyJustPressed([Z, UP, SPACE]);
		var touching_ground = character.isTouching(FlxObject.FLOOR);
		var touching_wall_left = character.isTouching(FlxObject.LEFT);
		var touching_wall = touching_wall_left || character.isTouching(FlxObject.RIGHT);
		var did_jump = false;

		// UPDATE STATE
		switch (state)
		{
			case GROUND:
				if (memory.init)
				{
					memory.ledge_assist_timer = -1;
					memory.init = false;
				}

				if (just_jumped) // jump
				{
					character.jump(elapsed);
					did_jump = true;
					switchState(AIR(0));
				}
				else if (!touching_ground && memory.ledge_assist_timer < 0) // falling
					memory.ledge_assist_timer = 0;
				else if (touching_ground && memory.ledge_assist_timer >= 0) // need to reset timer
					memory.ledge_assist_timer = -1;
				else if (memory.ledge_assist_timer > ledge_assist_delay) // fall
					switchState(AIR(0));
			case AIR(n):
				if (memory.init)
				{
					memory.hold_jump_timer = 0;
					memory.jump_buffer_timer = -1;
					memory.init = false;
				}

				if (!FlxG.keys.anyPressed([Z, UP, SPACE]))
					memory.hold_jump_timer = -1;

				if (just_jumped && n + 1 < max_n_jumps) // double jump
				{
					switchState(AIR(n + 1));
					character.jump(elapsed);
					did_jump = true;
				}
				else if (!just_jumped
					&& memory.hold_jump_timer >= 0
					&& memory.hold_jump_timer <= hold_jump_delay) // holding jump key makes you go higher
					character.continue_jump(elapsed);
				else if (touching_ground
					&& memory.jump_buffer_timer >= 0
					&& memory.jump_buffer_timer <= jump_buffer_delay) // apply buffered jump
				{
					character.jump(elapsed);
					did_jump = true;
					switchState(AIR(0));
				}
				else if (touching_wall
					&& memory.jump_buffer_timer >= 0
					&& memory.jump_buffer_timer <= jump_buffer_delay) // apply buffered jump
				{
					character.jump(elapsed, true, touching_wall_left);
					did_jump = true;
					switchState(AIR(0));
				}
				else if (touching_ground)
					switchState(GROUND);
				else if (touching_wall)
					switchState(WALL(touching_wall_left));

				if (just_jumped && !did_jump) // pressed jump key but didn't jump, buffer it
					memory.jump_buffer_timer = 0;

			case WALL(left):
				if (memory.init)
				{
					memory.stick_wall_timer = 0;
					memory.init = false;
				}

				if (just_jumped)
				{
					character.jump(elapsed, true, left);
					did_jump = true;
					switchState(AIR(0));
				}
				else if (memory.stick_wall_timer > stick_wall_delay)
				{
					switchState(AIR(0));
					if (left)
						character.acceleration.x += 1;
					else
						character.acceleration.x -= 1;
				}
				else if (touching_ground)
					switchState(GROUND);
		}

		// UPDATE MEMORY

		memory.did_jump = did_jump;

		if (memory.hold_jump_timer >= 0)
			memory.hold_jump_timer += elapsed;

		if (memory.jump_buffer_timer >= 0)
			memory.jump_buffer_timer += elapsed;

		if (memory.ledge_assist_timer >= 0)
			memory.ledge_assist_timer += elapsed;

		if (memory.stick_wall_timer >= 0)
			memory.stick_wall_timer += elapsed;
	}

	function switchState(new_state:MachineState)
	{
		memory.last_state = state;
		state = new_state;
		memory.init = true;
	}
}
