import flixel.FlxG;
import flixel.addons.editors.tiled.TiledMap;
import flixel.input.keyboard.FlxKey;

typedef Control =
{
	left:Bool,
	right:Bool,
	jump:Bool,
	reset:Bool,
	menu:Bool,
}

class KeyboardController
{
	public static var left_keys = [Q, LEFT];
	public static var right_keys = [D, RIGHT];
	public static var jump_keys = [Z, UP, SPACE];
	public static var reset_keys = [R, BACKSPACE];
	public static var menu_keys = [ESCAPE];

	public static function get()
	{
		return {
			left: FlxG.keys.anyPressed(left_keys),
			right: FlxG.keys.anyPressed(right_keys),
			jump: FlxG.keys.anyPressed(jump_keys),
			reset: FlxG.keys.anyJustPressed(reset_keys),
			menu: FlxG.keys.anyJustPressed(menu_keys),
		}
	}
}

class AIController
{
	var tiled_map:TiledMap;
	var character:Character;

	public function new(character:Character, tiled_map:TiledMap)
	{
		this.tiled_map = tiled_map;
		this.character = character;
	}

	public function get()
	{
		return {
			left: false,
			right: true,
			jump: false,
			reset: false,
			menu: false,
		}
	}
}
