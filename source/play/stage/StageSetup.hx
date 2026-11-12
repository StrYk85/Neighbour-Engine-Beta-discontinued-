package play.stage;

import flixel.util.FlxColor;
using StringTools;

typedef ObjectData = {
    var name:String;
    var assetPath:String;
    var position:Array<Float>;
    var scrollFactor:Array<Float>;
    var scale:Float;
    var angle:Float;
    var alpha:Float;
    var antialiasing:Bool;
    var color:FlxColor;
    var animations:Array<AnimationData>;
}

typedef AnimationData = {
    var name:String;
    var prefix:String;
	var offsets:Array<Float>;
    var framerate:Int;
    var loop:Bool;
    var indices:Array<Int>;
	var loopIndices:Array<Int>;
}

class StageSetup {
    public static function preCreate() {

    }

    public static function postCreate() {
        
    }

    public static function update() {
        
    }

    public static function beatHit(curBeat:Int):Void {
    }

    public static function stepHit(curStep:Int):Void {
        
    }
}