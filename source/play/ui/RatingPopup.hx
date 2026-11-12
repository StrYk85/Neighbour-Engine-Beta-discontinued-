package play.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class RatingPopup extends FlxSpriteGroup {

    public var pathPrefix:String = '';
    public var pathSuffix:String = '';

    public var rating:FlxSprite;
    public var msTxt:FlxText;
    public var numbers:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

    public function new(pathPrefix:String, pathSuffix:String) {
        super();

        this.pathPrefix = 'notestyles/$pathPrefix';
        this.pathSuffix = pathSuffix;

        rating = new FlxSprite().loadGraphic(Paths.image(pathPrefix + 'sick' + pathSuffix));
        rating.scrollFactor.set();
        rating.alpha = 0.001;
        rating.scale.set(0.7, 0.7);
        add(rating);

        msTxt = new FlxText(0, 0, 0, '0ms', 20);
        msTxt.borderStyle = OUTLINE;
		msTxt.borderSize = 1;
		msTxt.borderColor = 0xFF000000;
        msTxt.scrollFactor.set();
        msTxt.alpha = 0.001;
        add(msTxt);
    }

    public function displayRating(totalRating:String) {
        if (totalRating == null) totalRating = 'good';

        rating.acceleration.set();
        rating.velocity.set();
        FlxTween.cancelTweensOf(rating);
        rating.alpha = 1;
        rating.active = true;

        rating.loadGraphic(Paths.image(pathPrefix + totalRating + pathSuffix));
        rating.setPosition(Std.int(this.x), Std.int(this.y));

        rating.acceleration.y = 550;
        rating.velocity.y -= FlxG.random.int(140, 175);
        rating.velocity.x -= FlxG.random.int(0, 10);

        FlxTween.tween(rating, {alpha: 0.001}, 0.2, {onComplete: function(tween:FlxTween) {rating.active = false;}, startDelay: play.Conductor.crochet * 0.001});
    }

    public function displayMS(combo:Int, msShit:Float, totalRating:String) {
        if (totalRating == null) totalRating = 'good';

        FlxTween.cancelTweensOf(msTxt);
        msTxt.alpha = 1;
        msTxt.active = true;

        msTxt.text = 'Combo: ' + combo + ' | ' + msShit + 'ms';
        msTxt.color = totalRating == 'sick'? FlxColor.CYAN : totalRating == 'good'? FlxColor.GREEN : FlxColor.RED;

        msTxt.x = Std.int(rating.x + 100);
		msTxt.y = Std.int(rating.y + 125);

        FlxTween.tween(msTxt, {alpha: 0.001}, 0.2, {onComplete: function(tween:FlxTween) {msTxt.active = false;}, startDelay: play.Conductor.crochet * 0.001});
    }
}