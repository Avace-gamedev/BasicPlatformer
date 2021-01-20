import flixel.FlxG;
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
