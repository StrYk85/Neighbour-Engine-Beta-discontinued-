package states;

import flixel.input.gamepad.FlxGamepad;
import backend.Controls.KeyboardScheme;
import backend.Defaults;
import flixel.FlxG;
import flixel.FlxObject;
import graphics.FunkinSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import debug.DebugMenu;

using StringTools;

class MainMenuState extends ui.MusicBeatState
{
	private var colorsToUse:Array<Array<FlxColor>> = [[0xFFFDE871, 0xFFDC7727],[0xFFFD719B, 0xFFDD29A7]];

	var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FunkinSprite>;
	//var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];
	var optionShit:Array<String> = ['freeplay', 'donate', 'options'];

	var bgBlank:FunkinSprite;
	var bgOutline:FunkinSprite;
	var camFollow:FlxObject;

	override function create()
	{
		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		persistentUpdate = persistentDraw = true;

		bgBlank = new FunkinSprite(-80, 0);
		bgBlank.makeSolid(1,1, -1);
		bgBlank.color = colorsToUse[0][0];

		bgOutline = new FunkinSprite(-80, 0);
		bgOutline.loadGraphic(Paths.image('mainmenu/menuOutline'));
		bgOutline.scrollFactor.x = 0;
		bgOutline.scrollFactor.y = 0.15;
		bgOutline.setGraphicSize(Std.int(bgOutline.width * 1.1));
		bgBlank.setGraphicSize(Std.int(bgOutline.width * 1.1), Std.int(bgOutline.height * 1.1));
		bgBlank.scrollFactor.set();

		bgOutline.updateHitbox();
		bgOutline.screenCenter();

		bgBlank.updateHitbox();
		bgBlank.screenCenter();

		bgOutline.antialiasing = true;
		bgOutline.color = colorsToUse[0][1];
		add(bgBlank);
		add(bgOutline);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		menuItems = new FlxTypedGroup<FunkinSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('mainmenu/FNF_main_menu_assets');
		for (i in 0...optionShit.length)
		{
			var menuItem:FunkinSprite = new FunkinSprite(0, FlxG.height * 1.6);
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			menuItem.y = 60 + (i * 160);
		}

		FlxG.camera.follow(camFollow, null, 0.15);

		controls.setKeyboardScheme(KeyboardScheme.Solo, true);
		changeItem(0, true);

		super.create();
		if (leftWatermark != null) leftWatermark.text = Defaults.GAME_VERSION + ' FNF - ' + Defaults.ENGINE_TITLE + ' ' + Defaults.ENGINE_VERSION;
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin)
		{
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			if (gamepad != null) changeItem(gamepad.justPressed.DPAD_UP? -1 : gamepad.justPressed.DPAD_DOWN? 1 : 0);
			changeItem(FlxG.keys.justPressed.UP? -1 : FlxG.keys.justPressed.DOWN? 1 : 0);

			if (controls.BACK) FlxG.switchState(new TitleState());

			if (FlxG.keys.justPressed.SEVEN) {
				selectedSomethin = true;
				FlxG.switchState(new DebugMenu());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate') CoolUtil.fancyOpenURL("https://ninja-muffin24.itch.io/funkin");
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					bgBlank.color = colorsToUse[1][0];
					bgOutline.color = colorsToUse[1][1];

					menuItems.forEach(function(spr:FunkinSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 1.3, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) {
								goToState();
							});
						}
					});
				}
			}
		}

		super.update(elapsed);
		menuItems.forEach((spr:FunkinSprite) -> spr.screenCenter(X));
	}
	
	function goToState()
	{
		switch (optionShit[curSelected])
		{
			// case 'story mode':
			// 	FlxG.switchState(new StoryMenuState());
			// 	trace("Story Menu Selected");
			case 'freeplay':
				FlxG.switchState(new FreeplayState());
				trace("Freeplay Menu Selected");
			case 'options':
				FlxG.switchState(new OptionsMenu());
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
		});
	}
}
