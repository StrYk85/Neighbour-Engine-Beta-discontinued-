package;

import flixel.input.gamepad.FlxGamepad;
import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
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

import ui.DefaultText;

using StringTools;

class MainMenuState extends MusicBeatState
{
	private var colorsToUse:Array<Array<FlxColor>> = [[0xFFFDE871, 0xFFDC7727],[0xFFFD719B, 0xFFDD29A7]];

	var curSelected:Int = 0;
	var menuItems:FlxTypedGroup<FlxSprite>;
	//var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];
	var optionShit:Array<String> = ['freeplay', 'donate', 'options'];

	var bgBlank:FlxSprite;
	var bgOutline:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		persistentUpdate = persistentDraw = true;

		bgBlank = new FlxSprite(-80).makeGraphic(1,1, -1);
		bgBlank.color = colorsToUse[0][0];

		bgOutline = new FlxSprite(-80).loadGraphic(Paths.image('menuOutline'));
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

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('mainmenu/FNF_main_menu_assets');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, FlxG.height * 1.6);
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

		if (FlxG.save.data.dfjk)
			controls.setKeyboardScheme(KeyboardScheme.Solo, true);
		else
			controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);

		changeItem();

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

			if (gamepad != null)
			{
				if (gamepad.justPressed.DPAD_UP)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(-1);
				}
				if (gamepad.justPressed.DPAD_DOWN)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(1);
				}
			}

			if (FlxG.keys.justPressed.UP)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (FlxG.keys.justPressed.DOWN)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
				FlxG.switchState(new TitleState());

			if (FlxG.keys.justPressed.SEVEN) {
				selectedSomethin = true;
				FlxG.switchState(new DebugMenu());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
					CoolUtil.fancyOpenURL("https://ninja-muffin24.itch.io/funkin");
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					bgBlank.color = colorsToUse[1][0];
					bgOutline.color = colorsToUse[1][1];

					menuItems.forEach(function(spr:FlxSprite)
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

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}
	
	function goToState()
	{
		var daChoice:String = optionShit[curSelected];

		switch (daChoice)
		{
			case 'story mode':
				FlxG.switchState(new StoryMenuState());
				trace("Story Menu Selected");
			case 'freeplay':
				FlxG.switchState(new FreeplayState());

				trace("Freeplay Menu Selected");

			case 'options':
				FlxG.switchState(new OptionsMenu());
		}
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
	}
}
