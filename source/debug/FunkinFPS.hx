package debug;

import flixel.util.FlxStringUtil;

class FunkinFPS extends openfl.text.TextField {
	public var currentFPS(default, null):Int;
	private var memPeak:Float = 0;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 3, color:Int = 0xFFFFFF) {
		super();
		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new openfl.text.TextFormat('VCR OSD Mono', 12, color);
        autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
		times = [];
	}

	private override function __enterFrame(deltaTime:Float):Void {
		var currentTime:Float = openfl.Lib.getTimer();
		times.push(currentTime);

		while (times[0] < currentTime - 1000) times.shift();

        currentFPS = times.length;

		var mem = openfl.system.System.totalMemoryNumber;
		if (mem > memPeak) memPeak = mem;

        text = 'FPS: ' + currentFPS + ' | GC MEM: ' + FlxStringUtil.formatBytes(mem) + ' / ' + FlxStringUtil.formatBytes(memPeak);
	}
}