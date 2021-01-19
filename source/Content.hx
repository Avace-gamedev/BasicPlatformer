typedef Level = String;
typedef Area = Array<Level>;

class Content
{
	public static var areas:Array<Area>;

	public static function load()
	{
		// area 0
		var area0 = [
			AssetPaths.Area_0_Level_0__tmx,
			AssetPaths.Area_0_Level_1__tmx,
			AssetPaths.Area_0_Level_2__tmx,
			AssetPaths.Area_0_Level_3__tmx,
			AssetPaths.Area_0_Level_4__tmx,
		];

		areas = [area0];
	}
}
