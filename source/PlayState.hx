package;

import Panel.Control;
import Panel.EndGame;
import Panel.Info;
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
	var area_i:Int;
	var level_i:Int;

	var level:TiledLevel;

	public var player:Character;
	public var exit:FlxSprite;
	public var checkpoint_i:Int;
	public var checkpoints:Array<FlxSprite> = [];

	var status:EndGame;

	var spike_height:Int = 5; // in pixels, this is used to check if there is an actual overlap with the spikes

	override public function new(area_i:Int = 0, level_i:Int = 0, checkpoint_i = -1)
	{
		super();

		this.area_i = area_i;
		this.level_i = level_i;
		this.checkpoint_i = checkpoint_i;
	}

	override public function create()
	{
		FlxG.mouse.visible = false;
		FlxG.autoPause = false;
		FlxG.camera.bgColor = 0xFFFFFFFF;

		super.create();

		Content.load();

		// END CONFIG

		player = new Character();
		FlxG.camera.follow(player);

		exit = new FlxSprite(0, 0);
		exit.makeGraphic(32, 32, 0xff00ff00);

		// level = new TiledLevel(AssetPaths.second__tmx, this);
		level = new TiledLevel(Content.areas[area_i][level_i], this);
		add(level.backgroundLayer);
		add(level.imagesLayer);
		add(level.objectsLayer);
		add(level.foregroundTiles);

		// UI

		var ctrl_panel = new Control([["← →", "move"], ["↑", "jump"], ["R", "reset"]], new FlxPoint(level.tileWidth, 0), 16, FlxColor.fromInt(0xFF444444));
		add(ctrl_panel);

		var level_text = new Info(area_i, level_i);
		level_text.x = FlxG.camera.width - level.tileWidth - level_text.width;
		add(level_text);

		status = new EndGame();
		status.visible = false;
		add(status);

		// CHECKPOINT

		if (checkpoint_i >= 0)
		{
			player.x = checkpoints[checkpoint_i].x + checkpoints[checkpoint_i].width / 2;
			player.y = checkpoints[checkpoint_i].y + checkpoints[checkpoint_i].height / 2;
		}

		for (i in 0...checkpoint_i)
		{
			checkpoints[i].active = false;
			checkpoints[i].visible = false;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		level.update(elapsed);

		// collision with white tiles
		level.collideWithGround(player);

		// collision with red spikes
		if (level.collideWithSpikes(player) || FlxG.keys.justPressed.R)
			resetLevel();

		// win condition
		FlxG.overlap(exit, player, win);

		// hit checkpoint
		for (i in 0...checkpoints.length)
			if (checkpoints[i].active)
				FlxG.overlap(checkpoints[i], player, function(_, _)
				{
					checkpoints[i].active = false;
					checkpoints[i].visible = false;
					checkpoint_i = i;
				});
	}

	public function resetLevel()
	{
		FlxG.switchState(new PlayState(area_i, level_i, checkpoint_i));
	}

	public function win(Exit:FlxObject, Player:FlxObject):Void
	{
		player.kill();

		if (level_i + 1 < Content.areas[area_i].length)
			FlxG.switchState(new PlayState(area_i, level_i + 1));
		else if (area_i + 1 < Content.areas.length)
			FlxG.switchState(new PlayState(area_i + 1, 0));
		else
			status.visible = true;
	}
}
