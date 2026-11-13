package play.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class RatingPopup extends flixel.group.FlxSpriteGroup {
    public var pathPrefix:String = '';
    public var pathSuffix:String = '';

    public var spriteBin:Map<String, Array<FlxSprite>> = [];

    public function new(pathPrefix:String, pathSuffix:String) {
        super();
        this.pathPrefix = 'notestyles/$pathPrefix';
        this.pathSuffix = pathSuffix;
    }

     override public function destroy():Void {
        super.destroy();
        for (pool in spriteBin) for (sprite in pool) sprite.destroy();
        spriteBin.clear();
    }

    public function getSprite(key:String = 'good', spritescale:Float = 0.7):FlxSprite {
        var bin = spriteBin.get(key);
        if (bin != null && bin.length > 0) {
            var sprite = bin.pop();
            sprite.acceleration.set();
            sprite.velocity.set();
            sprite.alpha = 1;
            return sprite;
        }
        if (bin == null) spriteBin.set(key, []);
        return createSprite(key, spritescale);
    }

    public function putSprite(key:String = 'good', sprite:FlxSprite) {
        var bin = spriteBin.get(key);
        if (bin == null) spriteBin.set(key, []);
        remove(sprite, true);
        bin.push(sprite);
    }

    public function createSprite(key:String = 'good', spritescale:Float = 0.7):FlxSprite {
        var dummy:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pathPrefix + key + pathSuffix));
        dummy.antialiasing = true;
        dummy.scrollFactor.set();
        dummy.scale.set(spritescale, spritescale);
        dummy.updateHitbox();
        return dummy;
    }

    public function displayRating(totalRating:String) {
        if (totalRating == null) totalRating = 'good';

        var rating = getSprite(totalRating, 0.7);
        if (rating == null) return;
        rating.setPosition(-rating.width/2, -rating.height/2);
        add(rating);

        rating.acceleration.y = 550;
        rating.velocity.set(-FlxG.random.int(0, 10), -FlxG.random.int(140, 175));

        FlxTween.tween(rating, {alpha: 0}, 0.2, {onComplete: function(tween:FlxTween) putSprite(totalRating, rating), startDelay: play.Conductor.crochet * 0.001});
    }
    
    public function displayNum(combo:Int = 0) {
        var comboString = Std.string(combo);
        while (comboString.length < 3) comboString = flixel.util.FlxStringUtil.insert(comboString, 0, '0');

        for (i in 0...comboString.length) {
            var name = 'num${comboString.charAt(i)}';
            var num = getSprite(name, 0.5);
            if (num == null) return;
            num.setPosition(-num.width/2 + (i * 45), -num.height/2 + 75);
            add(num);

            num.acceleration.y = FlxG.random.int(250, 300);
            num.velocity.set(FlxG.random.int(-5, 5), -FlxG.random.int(130, 150));

            FlxTween.tween(num, {alpha: 0}, 0.2, {onComplete: function(tween:FlxTween) putSprite(name, num), startDelay: play.Conductor.crochet * 0.002});
        }
    }

    public function displayFull(rating:String, combo:Int, forceCombo:Bool = false) {
        displayRating(rating);
        if (combo >= 10 || forceCombo) displayNum(combo);
    }
}