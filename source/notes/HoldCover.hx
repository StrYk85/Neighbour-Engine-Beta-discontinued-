package notes;

import flixel.FlxG;
import flixel.FlxSprite;

class HoldCover extends FlxSprite {

    private var strum:FlxSprite;

    public function new(noteData:Int, strum:FlxSprite) {
        super();
        this.strum = strum;

        var colors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];
        frames = Paths.getSparrowAtlas('notestyles/default/holdcovers/' + 'holdCover' + colors[Std.int(noteData % 4)]);
        animation.addByPrefix('start', 'holdCoverStart' + colors[Std.int(noteData % 4)], 24, false);
		animation.addByPrefix('idle', 'holdCover' + colors[Std.int(noteData % 4)], 24, true);
        animation.addByPrefix('end', 'holdCoverEnd' + colors[Std.int(noteData % 4)], 24, false);

        animation.onFinish.add(onAnimationFinish);
        playStart();
        trace('cover has been added!');
    }

    public function playStart() {
        animation.play('start', true);
        x = (strum.x + (strum.width - width) / 2) - 12;
        y = (strum.y + (strum.height - height) / 2) + 48;
        visible = true;
    }

    public function playIdle() {
        animation.play('idle');
    }

    public function playEnd() {
        animation.play('end');
    }

    public function onAnimationFinish(anim:String) {
        switch(anim) {
            case 'start': playIdle();
            case 'end': visible = false;
        }
    }
}