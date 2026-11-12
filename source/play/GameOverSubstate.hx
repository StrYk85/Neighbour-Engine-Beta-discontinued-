package play;

import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import play.stage.Character;

class GameOverSubstate extends ui.MusicBeatSubstate {
	var bf:Character;
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float) {
		super();
		Conductor.songPosition = 0;
		add(bf = new Character(x, y, 'bf-dead'));
		add(camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1));

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.ACCEPT) endBullshit();
		if (controls.BACK) {
			FlxG.sound.music.stop();
			//FlxG.switchState(PlayState.isStoryMode? new states.StoryMenuState() : new states.FreeplayState());
			FlxG.switchState(new states.FreeplayState());
		}
		if (bf.animation.curAnim.name == 'firstDeath') {
			if (bf.animation.curAnim.curFrame == 12) FlxG.camera.follow(camFollow, LOCKON, 0.01);
			if (bf.animation.curAnim.finished) FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
		}
		if (FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;
	}

	var isEnding:Bool = false;
	function endBullshit():Void {
		if (!isEnding) {
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) FlxG.camera.fade(FlxColor.BLACK, 2, false, function() states.LoadingState.loadAndSwitchState(new PlayState())));
		}
	}
}
