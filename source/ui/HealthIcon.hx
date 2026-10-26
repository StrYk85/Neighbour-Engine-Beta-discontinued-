package ui;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite {
	public var sprTracker:FlxSprite;

	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super();
		this.loadGraphic(Paths.image('icons/$char'), true, 150, 150);
		this.scrollFactor.set();
		this.flipX = isPlayer;

		antialiasing = true;
		animation.add('win', [0], 0, false, false);
		animation.add('lose', [1], 0, false, false);
		animation.play('win');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
