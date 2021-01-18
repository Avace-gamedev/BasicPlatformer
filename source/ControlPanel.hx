import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ControlPanel extends FlxTypedGroup<FlxText>
{
	override public function new(controls:Array<Array<String>>, offset:FlxPoint, font_size:Int, text_color:FlxColor)
	{
		super();
		var x_text:Float = 0;
		var cur_y:Float = 0;

		for (ctrl in controls)
		{
			var cmd_text = new FlxText(offset.x, offset.y + cur_y, 0, ctrl[0]);
			cmd_text.setFormat(null, font_size, text_color);
			cmd_text.scrollFactor.set(0, 0);
			add(cmd_text);
			x_text = cmd_text.width > x_text ? cmd_text.width : x_text;
			cur_y += cmd_text.height;
		}

		cur_y = 0;

		for (ctrl in controls)
		{
			var desc_text = new FlxText(offset.x + x_text, offset.y + cur_y, 0, ctrl[1]);
			desc_text.setFormat(null, font_size, text_color);
			desc_text.scrollFactor.set(0, 0);
			add(desc_text);
			cur_y += desc_text.height;
		}
	}
}
