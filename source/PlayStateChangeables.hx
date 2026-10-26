import flixel.FlxG;
class PlayStateChangeables {
    public static var useDownscroll:Bool;
    public static var safeFrames:Int;
    public static var scrollSpeed:Float;
    public static var botPlay:Bool;
    public static var optimize:Bool;

    public static function reset() {
        PlayStateChangeables.useDownscroll = FlxG.save.data.downscroll;
		PlayStateChangeables.safeFrames = FlxG.save.data.frames;
		PlayStateChangeables.scrollSpeed = FlxG.save.data.scrollSpeed;
		PlayStateChangeables.botPlay = FlxG.save.data.botplay;
		PlayStateChangeables.optimize = FlxG.save.data.optimize;
    }
}