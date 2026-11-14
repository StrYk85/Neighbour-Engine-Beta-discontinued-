package play.pause;

import graphics.FunkinSprite;
import flixel.input.gamepad.FlxGamepad;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import ui.DefaultText;
import ui.Alphabet;

typedef PauseEntry = {
	var text:String;
	var callback:() -> Void;
}

class PauseSubState extends ui.MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var callBacks:Array<() -> Void> = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var perSongOffset:DefaultText;
	
	var offsetChanged:Bool = false;

	public function setMenuArray():Array<PauseEntry> {
		var daArray:Array<PauseEntry> = [
			{text: 'Resume', callback: close},
			{text: 'Restart Song', callback: () -> FlxG.resetState()},
			{text: 'Options', callback: goToOptions},
			{text: 'Exit to Menu', callback: exitToMainMenu},
		];
		if (PlayState.inChartingState) daArray.insert(4, {text: 'Exit to Chart Editor', callback: () -> toState(new debug.ChartingState())});
		return daArray;
	}

	public function new() {
		super();
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		var bg:FunkinSprite = new FunkinSprite();
		bg.makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32).setFormat(Paths.font('vcr.ttf'), 32);
		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, CoolUtil.difficultyFromInt(PlayState.curDifficulty).toUpperCase(), 32).setFormat(Paths.font('vcr.ttf'), 32);
		for (i in [levelInfo, levelDifficulty]) {i.antialiasing = true; i.scrollFactor.set(); i.updateHitbox(); i.alpha = 0; add(i);}

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		
		#if cpp
			perSongOffset = new DefaultText(5, FlxG.height - 18, '');
			perSongOffset.text = 'Additive Offset (Left, Right): ' + PlayState.songOffset + ' - Description - ' + 'Adds value to global offset, per song.';
			perSongOffset.scrollFactor.set();
			add(perSongOffset);
		#end
		
		var menuItems = setMenuArray();
		var id = 0;
		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(0, (70 * id) + 30, menuItems[i].text, true, false);
			songText.isMenuItem = true;
			songText.targetY = id;
			if (menuItems[i].callback != null) {
				callBacks.push(menuItems[i].callback);
				grpMenuShit.add(songText);
				id++;
			}
		}

		changeSelection(0, true);
	}

	override function update(elapsed:Float) {
		if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		// disabling this until i find a solution
		// var leftP = controls.LEFT_P;
		// var rightP = controls.RIGHT_P;
		var leftP = false;
		var rightP = false;
		if (gamepad != null && backend.KeyBinds.gamepad) {
			upP = controls.UP_P || gamepad.justPressed.DPAD_UP;
			downP = controls.DOWN_P || gamepad.justPressed.DPAD_DOWN;
			// leftP = controls.LEFT_P || gamepad.justPressed.DPAD_LEFT;
			// rightP = controls.RIGHT_P || gamepad.justPressed.DPAD_RIGHT;
		}
		var accepted = controls.ACCEPT;
		var oldOffset:Float = 0;

		changeSelection(upP? -1 : downP? 1 : 0, false);
		
		#if cpp
		if (leftP || rightP) {
			oldOffset = PlayState.songOffset;
			PlayState.songOffset += leftP? -1 : 1;
			// pre lowercasing the song name (not on update)
			var songPath = 'assets/data/songs/' + StringTools.replace(PlayState.SONG.song, ' ', '-').toLowerCase() + '/';

			sys.FileSystem.rename(songPath + oldOffset + '.offset', songPath + PlayState.songOffset + '.offset');
			perSongOffset.text = 'Additive Offset (Left, Right): ' + PlayState.songOffset + ' - Description - ' + 'Adds value to global offset, per song.';

			// Prevent loop from happening every single time the offset changes
			if (!offsetChanged) {
				var offsetter = 0;
				for (a => item in grpMenuShit.members) {
					if (item.text == 'Resume') {
						offsetter = a + 1;
						grpMenuShit.remove(item, true);
						callBacks.remove(callBacks[a]);
					}
					else item.targetY -= offsetter;
				}

				changeSelection(0, true);
				offsetChanged = true;
			}
		}
		#end

		if (accepted && callBacks[curSelected] != null) callBacks[curSelected]();
	}

	override function destroy() {
		pauseMusic.destroy();
		super.destroy();
	}

	function toState(nextState:flixel.util.typeLimit.NextState) {
		if (FlxG.save.data.fpsCap > 290) (cast (openfl.Lib.current.getChildAt(0), Main)).setFPSCap(290);
		FlxG.switchState(nextState);
	}

	public function exitToMainMenu() {
		if (PlayState.isStoryMode) toState(new states.MainMenuState());
		else toState(new states.FreeplayState());
	}

	public function goToOptions() {
		states.OptionsMenu.fromPlayState = true;
		toState(new states.OptionsMenu());
	}

	function changeSelection(change:Int = 0, force:Bool):Void {
		if (change == 0 && !force) return;
		if (!force) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, grpMenuShit.length - 1);

		for (a => item in grpMenuShit.members) {
			item.targetY = a - curSelected;
			item.alpha = item.targetY == 0? 1 : 0.6;
		}
	}
}