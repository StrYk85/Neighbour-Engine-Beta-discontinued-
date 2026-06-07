package notes;

import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite {

    private var strum:FlxSprite;

    public function new(noteData:Int, strum:FlxSprite) {
        super();
        this.strum = strum;

        var colors:Array<String> = ['purple', 'blue', 'green', 'red'];
        frames = Paths.getSparrowAtlas('notestyles/default/' + 'NOTESPLASH_assets');
        animation.addByPrefix('splash0', 'note impact 1 ' + colors[Std.int(noteData % 4)] + '0', 24, false);
		animation.addByPrefix('splash1', 'note impact 2 ' + colors[Std.int(noteData % 4)] + '0', 24, false);

        alpha = .8;
		antialiasing = true;

        animation.onFinish.add((animName:String) -> visible = false);
        playAnim();
    }

    public function playAnim() {
        var rando:Int = FlxG.random.int(0, 1);
        animation.play('splash' + rando, true);
        
        updateHitbox();
        centerOffsets();
        centerOrigin();

        x = strum.x + (strum.width - width) / 2;
        y = strum.y + (strum.height - height) / 2;
        visible = true;
    }
}