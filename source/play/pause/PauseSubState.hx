package play.pause;

import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
import backend.Controls.Control;
import flixel.FlxG;
import graphics.FunkinSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import ui.DefaultText;
import ui.Alphabet;

class PauseSubState extends ui.MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var perSongOffset:DefaultText;
	
	var offsetChanged:Bool = false;

	public function new()
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FunkinSprite = new FunkinSprite();
		bg.makeSolid(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		
		#if cpp
			perSongOffset = new DefaultText(5, FlxG.height - 18, "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.');
			perSongOffset.scrollFactor.set();
			add(perSongOffset);
		#end

		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection(0, true);
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		if (gamepad != null && backend.KeyBinds.gamepad) {
			upP = gamepad.justPressed.DPAD_UP;
			downP = gamepad.justPressed.DPAD_DOWN;
			leftP = gamepad.justPressed.DPAD_LEFT;
			rightP = gamepad.justPressed.DPAD_RIGHT;
		}
		var accepted = controls.ACCEPT;
		var oldOffset:Float = 0;

		changeSelection(upP? -1 : downP? 1 : 0, false);
		
		#if cpp
		if (leftP || rightP) {
			oldOffset = PlayState.songOffset;
			PlayState.songOffset += leftP? -1 : 1;
			// pre lowercasing the song name (not on update)
			var songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
			var songPath = 'assets/data/songs/' + songLowercase + '/';

			sys.FileSystem.rename(songPath + oldOffset + '.offset', songPath + PlayState.songOffset + '.offset');
			perSongOffset.text = "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.';

			// Prevent loop from happening every single time the offset changes
			if (!offsetChanged) {
				grpMenuShit.clear();
				menuItems = ['Restart Song', 'Exit to menu'];

				for (i in 0...menuItems.length) {
					var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
					songText.isMenuItem = true;
					songText.targetY = i;
					grpMenuShit.add(songText);
				}

				changeSelection(0, true);
				offsetChanged = true;
			}
		}
		#end

		if (accepted) {
			switch (menuItems[curSelected]) {
				case "Resume":
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Exit to menu":
					if (FlxG.save.data.fpsCap > 290) (cast (Lib.current.getChildAt(0), Main)).setFPSCap(290);
					FlxG.switchState(new states.MainMenuState());
			}
		}
	}

	override function destroy() {
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0, force:Bool):Void {
		if (change == 0 && !force) return;
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);

		for (a => item in grpMenuShit.members) {
			item.targetY = a - curSelected;
			item.alpha = item.targetY == 0? 1 : 0.6;
		}
	}
}