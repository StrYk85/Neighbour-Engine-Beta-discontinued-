package debug;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Lib;
import openfl.system.System;
import flixel.util.FlxStringUtil;

class FunkinFPS extends TextField
{
    /**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	private var memPeak:Float = 0;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 3, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 12, color);
        autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
		times = [];
	}

	private override function __enterFrame(deltaTime:Float):Void {
		var currentTime:Float = Lib.getTimer();
		times.push(currentTime);

		while (times[0] < currentTime - 1000) times.shift();

        currentFPS = times.length;

		var mem = System.totalMemoryNumber;
		if (mem > memPeak) memPeak = mem;

        text = 'FPS: ' + currentFPS + ' | Memory: ' + FlxStringUtil.formatBytes(mem) + ' / ' + FlxStringUtil.formatBytes(memPeak);
		textColor = 0xFFFFFFFF;
		
	}
}