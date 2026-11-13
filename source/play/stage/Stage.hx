package play.stage;

typedef ObjectData = {
    var name:String;
    var assetPath:String;
    var position:Array<Float>;
    var scrollFactor:Array<Float>;
    var scale:Float;
    var angle:Float;
    var alpha:Float;
    var antialiasing:Bool;
    var color:flixel.util.FlxColor;
    var animations:Array<backend.AnimationData>;
}