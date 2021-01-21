import flixel.FlxG;
import flixel.addons.editors.tiled.TiledMap;
import flixel.input.keyboard.FlxKey;

typedef Control =
{
	left:Bool,
	right:Bool,
	jump:Bool,
}

class Controller
{
	var character:Character;

	public function new() {}

	public function bind(character:Character)
		this.character = character;

	public function get(control:Control) {}
}

class KeyboardController extends Controller
{
	public static var left_keys = [Q, LEFT];
	public static var right_keys = [D, RIGHT];
	public static var jump_keys = [Z, UP, SPACE];

	override public function new()
	{
		super();
	}

	override public function get(control:Control)
	{
		control.left = FlxG.keys.anyPressed(left_keys);
		control.right = FlxG.keys.anyPressed(right_keys);
		control.jump = FlxG.keys.anyPressed(jump_keys);
	}
}

class AIController extends Controller
{
	var tiled_map:TiledMap;

	override public function new(tiled_map:TiledMap)
	{
		super();
		this.tiled_map = tiled_map;
	}

	override public function get(control:Control)
	{
		control.left = false;
		control.right = true;
		control.jump = false;
	}
}
