package states;

import flixel.input.gamepad.FlxGamepad;
import backend.Controls.KeyboardScheme;
import backend.Defaults;
import flixel.FlxG;
import flixel.FlxObject;
import graphics.FunkinSprite;
import graphics.DynamicBackground;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

using StringTools;

class MainMenuState extends ui.MusicBeatState {
	var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FunkinSprite>;
	var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];

	var bg:DynamicBackground;
	var camFollow:FlxObject;

	override function create() {
		if (!FlxG.sound.music.playing) FlxG.sound.playMusic(Paths.music('freakyMenu'));
		persistentUpdate = persistentDraw = true;

		bg = new DynamicBackground();
		bg.setPosition(-80, -40);
		bg.setScale(1.1, 1.1);
		bg.scrollFactor.set(0, 0.15);
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		menuItems = new FlxTypedGroup<FunkinSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('mainmenu/FNF_main_menu_assets');
		for (i in 0...optionShit.length) {
			var menuItem:FunkinSprite = new FunkinSprite(0, FlxG.height * 1.6);
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + ' basic', 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + ' white', 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			menuItem.y = 60 + (i * 160);
		}

		FlxG.camera.follow(camFollow, null, 0.15);
		changeItem(0, true);

		super.create();
		if (leftWatermark != null) leftWatermark.text = Defaults.GAME_VERSION + ' FNF - ' + Defaults.ENGINE_TITLE + ' ' + Defaults.ENGINE_VERSION;
	}

	function toState(nextState:flixel.util.typeLimit.NextState) {
		canInteract = false;
		FlxG.switchState(nextState);
	}

	var canInteract:Bool = true;
	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8) FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (canInteract) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			if (gamepad != null) changeItem(gamepad.justPressed.DPAD_UP? -1 : gamepad.justPressed.DPAD_DOWN? 1 : 0);
			changeItem(FlxG.keys.justPressed.UP? -1 : FlxG.keys.justPressed.DOWN? 1 : 0);

			if (controls.BACK) toState(new TitleState());
			if (FlxG.keys.justPressed.SEVEN) toState(new debug.DebugMenu());

			if (controls.ACCEPT) {
				canInteract = false;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				bg.setSelectedColor(1);

				menuItems.forEach(function(spr:FunkinSprite) {
					if (curSelected != spr.ID) FlxTween.tween(spr, {alpha: 0}, 1.3, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) spr.kill()});
					else FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) goToState());
				});
			}
		}

		super.update(elapsed);
	}
	
	function goToState()
	{
		switch (optionShit[curSelected])
		{
			// case 'story mode':
			// 	toState(new StoryMenuState());
			case 'freeplay':
				toState(new FreeplayState());
			case 'options':
				toState(new OptionsMenu());
			case 'donate':
				CoolUtil.fancyOpenURL('https://ninja-muffin24.itch.io/funkin');
				canInteract = true;
			default: 
				canInteract = true;
		}
	}

	function changeItem(change:Int = 0, ?force:Bool = false)
	{
		if (change == 0 && !force) return;
		if (!force) FlxG.sound.play(Paths.sound('scrollMenu'));
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		menuItems.forEach(function(spr:FunkinSprite)
		{
			spr.playAnim(spr.ID == curSelected? 'selected' : 'idle');
			if (spr.ID == curSelected) camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			spr.updateHitbox();
			spr.screenCenter(X);
		});
	}
}
