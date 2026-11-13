package graphics;

import flixel.util.FlxColor;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class FunkinSprite extends flixel.FlxSprite {
    public var animOffsets:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();
    public var zIndex:Int;

    public function makeSolid(sWidth:Float, sHeight:Float, col:FlxColor) {
        makeGraphic(1, 1, col);
        setGraphicSize(sWidth, sHeight);
        updateHitbox();
    }

    public function setScale(amount:Float, hitboxUpdate:Bool = false):Void {
        scale.set(amount, amount);
        if (hitboxUpdate) updateHitbox();
    }

    public function loadSparrow(assetPath:String):Void {
        frames = Paths.getSparrowAtlas(assetPath);
    }

    public function loadPacker(assetPath:String):Void {
        frames = Paths.getPackerAtlas(assetPath);
    }

    public function playAnimation(animationName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		animation.play(animationName, force, reversed, frame);

        var daOffset = animOffsets.get(animationName);
		if (animOffsets.exists(animationName)) offset.set(daOffset[0], daOffset[1])
		else offset.set();
    }

    public function playAnim(animationName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
        playAnimation(animationName, force, reversed, frame);
    }

    public function addAnimation(name:String, prefix:String, indices:Null<Array<Int>> = null, offsets:Null<Array<Float>> = null, fps:Int = 24, loop:Bool = false):Void {
        if (indices != null && indices.length > 0) animation.addByIndices(name, prefix, indices, '', fps ?? 24, loop ?? false);
        else animation.addByPrefix(name, prefix, fps ?? 24, loop ?? false);
        if (offsets != null && offsets.length > 0) addOffset(name, offsets[0] ?? 0.0, offsets[1] ?? 0.0);
    }

    public function addAnim(name:String, prefix:String, indices:Array<Int> = null, offsets:Array<Float> = null, fps:Int = 24, loop:Bool = false):Void {
        addAnimation(name, prefix, indices, offsets, fps, loop);
    }

    public function animationStartsWith(name:String):Bool {
        return animation.curAnim.name.startsWith(name);
    }

    public function animationExists(name:String):Bool {
        return animation.exists(name);
    }

    public function addOffset(name:String, x:Float = 0, y:Float = 0):Void {
		animOffsets[name] = [x, y];
	}
}