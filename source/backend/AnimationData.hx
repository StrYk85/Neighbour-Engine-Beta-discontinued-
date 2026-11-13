package backend;

typedef AnimationData = {
    var name:String;
    var prefix:String;
	var offsets:Array<Float>;
    var framerate:Int;
    var loop:Bool;
    var indices:Array<Int>;
	var loopIndices:Array<Int>;
}