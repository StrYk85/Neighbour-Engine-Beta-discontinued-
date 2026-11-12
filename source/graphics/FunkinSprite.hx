package graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

class FunkinSprite extends FlxSprite {
    public var name:String = '';
    public var shouldAlternate:Bool = false;

    public var danced:Bool = false;

    public function new (?x:Float = 0, ?y:Float = 0, ?name:String = null) {
        super(x, y);
        this.name ??= name;
    }

    public function makeSolid(sWidth:Float, sHeight:Float, col:FlxColor) {
        makeGraphic(1, 1, col);
        setGraphicSize(sWidth, sHeight);
        updateHitbox();
    }

    public function dance() {
        if (shouldAlternate) {
            if (danced) playAnim('danceRight');
            else playAnim('danceLeft');
            danced = !danced;
        }
        else 
            playAnim('idle');
    }

    public function playAnim(animationName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void {
		animation.play(animationName, force, reversed, frame);
    }
}