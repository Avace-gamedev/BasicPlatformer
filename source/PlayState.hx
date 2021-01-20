package;

import Controller.Control;
import Controller.KeyboardController;
import Panel.ControlPanel;
import Panel.EndGamePanel;
import Panel.InfoPanel;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tile.FlxTile;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{
	var area_i:Int;
	var level_i:Int;
	var checkpoint_i:Int;
	var sound:FlxSound;

	var level:TiledLevel;

	public var player:Character;
	public var exit:FlxSprite;
	public var checkpoints:Array<FlxSprite> = [];

	var status:EndGamePanel;

	var spike_height:Int = 5; // in pixels, this is used to check if there is an actual overlap with the spikes

	override public function new(area_i:Int = 0, level_i:Int = 0, checkpoint_i = -1, sound:FlxSound = null)
	{
		super();

		this.area_i = area_i;
		this.level_i = level_i;
		this.checkpoint_i = checkpoint_i;
		this.sound = sound;
	}

	override public function create()
	{
		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		FlxG.camera.bgColor = 0xFFFFFFFF;

		super.create();

		Content.load();

		if (sound != null)
			sound.play();

		// END CONFIG

		player = new Character(area_i > 0 || level_i >= 5);
		FlxG.camera.follow(player);

		exit = new FlxSprite(0, 0);
		exit.makeGraphic(32, 32, 0xff00ff00);

		// level = new TiledLevel(AssetPaths.second__tmx, this);
		level = new TiledLevel(Content.areas[area_i][level_i], this);
		add(level.backgroundLayer);
		add(level.imagesLayer);
		add(level.objectsLayer);
		add(level.foregroundTiles);

		// TMP
		// var overlay = new FlxSprite();
		// overlay.makeGraphic(level.fullWidth, level.fullHeight, FlxColor.TRANSPARENT);
		// add(overlay);
		// for (i in 0...level.tilemap_desc.collisions.length)
		// 	if (level.tilemap_desc.collisions[i])
		// 	{
		// 		var t_x:Int = i % level.tilemap_desc.width;
		// 		var t_y:Int = Math.floor(i / level.tilemap_desc.width);
		// 		if (level.isSpike(level.tilemap_desc.tiles[i]))
		// 			FlxSpriteUtil.drawCircle(overlay, (t_x + 0.5) * level.tilemap_desc.tile_size, (t_y + 0.5) * level.tilemap_desc.tile_size, 10,
		// 				FlxColor.RED);
		// 		else
		// 			FlxSpriteUtil.drawCircle(overlay, (t_x + 0.5) * level.tilemap_desc.tile_size, (t_y + 0.5) * level.tilemap_desc.tile_size, 10,
		// 				FlxColor.GRAY);
		// 	}

		// FlxSpriteUtil.drawCircle(overlay, (level.tilemap_desc.starting_pos.x + 0.5) * level.tilemap_desc.tile_size,
		// 	(level.tilemap_desc.starting_pos.y + 0.5) * level.tilemap_desc.tile_size, 10, FlxColor.BLUE);
		// FlxSpriteUtil.drawCircle(overlay, (level.tilemap_desc.exit_pos.x + 0.5) * level.tilemap_desc.tile_size,
		// 	(level.tilemap_desc.exit_pos.y + 0.5) * level.tilemap_desc.tile_size, 10, FlxColor.GREEN);

		// var g = new PathingGraph(level);
		// for (i in 0...g.segments.length)
		// 	FlxSpriteUtil.drawLine(overlay, g.segments[i].start_x * level.tileWidth, g.segments[i].y * level.tileHeight + 16,
		// 		(g.segments[i].end_x + 1) * level.tileWidth, g.segments[i].y * level.tileHeight + 16, {
		// 		color: FlxColor.RED
		// 	});

		// UI

		var controls = [["← →", "move"], ["↑", "jump"], ["R", "reset"], ["Esc", "Menu"]];

		if (area_i > 0 || level_i >= 5)
		{
			controls = [
				["← →", "move"],
				["↑", "jump"],
				["↑ ↑", "double jump"],
				["R", "reset"],
				["Esc", "Menu"],
			];
		}

		if (area_i == 0 && level_i == 5 && checkpoint_i == -1)
		{
			var text = new FlxText(level.tileWidth, 28 * level.tileHeight, 27 * level.tileWidth, "Unlocked: Double Jump", 48);
			text.alignment = CENTER;
			add(text);
			haxe.Timer.delay(function() text.visible = false, 2000);
		}

		var ctrl_panel = new ControlPanel(controls, new FlxPoint(level.tileWidth * 1.5, 0), 16, FlxColor.fromInt(0xFF444444));
		add(ctrl_panel);

		var level_text = new InfoPanel(area_i, level_i);
		level_text.x = FlxG.camera.width - level.tileWidth - level_text.width;
		add(level_text);

		status = new EndGamePanel();
		status.visible = false;
		add(status);

		// CHECKPOINT

		if (checkpoint_i >= 0)
		{
			player.x = checkpoints[checkpoint_i].x + checkpoints[checkpoint_i].width / 2;
			player.y = checkpoints[checkpoint_i].y + checkpoints[checkpoint_i].height / 2;
		}

		for (i in 0...(checkpoint_i + 1))
		{
			checkpoints[i].active = false;
			checkpoints[i].visible = false;
		}
	}

	override public function update(elapsed:Float)
	{
		var control = KeyboardController.get();
		player.doUpdate(elapsed, control);

		super.update(elapsed);
		level.update(elapsed);

		// collision with white tiles
		level.collideWithGround(player);

		// collision with red spikes
		if (level.collideWithSpikes(player) || control.reset)
			FlxG.switchState(new PlayState(area_i, level_i, checkpoint_i, Content.sound_damage));

		if (control.menu)
			FlxG.switchState(new MenuState());

		// win condition
		FlxG.overlap(exit, player, win);

		// hit checkpoint
		for (i in 0...checkpoints.length)
			if (checkpoints[i].active)
				FlxG.overlap(checkpoints[i], player, function(_, _)
				{
					Content.sound_checkpoint.play();
					checkpoints[i].active = false;
					checkpoints[i].visible = false;
					checkpoint_i = i;
				});
	}

	public function win(Exit:FlxObject, Player:FlxObject):Void
	{
		player.kill();

		if (level_i + 1 < Content.areas[area_i].length)
			FlxG.switchState(new PlayState(area_i, level_i + 1, -1, Content.sound_exit));
		else if (area_i + 1 < Content.areas.length)
			FlxG.switchState(new PlayState(area_i + 1, 0, -1, Content.sound_exit));
		else
		{
			status.visible = true;
			Content.sound_exit.play();
		}
	}
}
