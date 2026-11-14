package debug;

import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.Lib;
import backend.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import graphics.FunkinSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;

class DebugMenu extends ui.MusicBeatState
{
	var curSelected:Int = 0;
	var options:Array<String> = ['chart editor', 'animation editor'];

	public var acceptInput:Bool = true;
	private var grpControls:FlxTypedGroup<Alphabet>;
	public static var versionShit:FlxText;
	
	override function create() {
		var menuBG:FunkinSprite = new FunkinSprite();
		menuBG.loadGraphic(Paths.image('mainmenu/menuDesat'));

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...options.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, options[i], true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
		}

		versionShit = new FlxText(5, FlxG.height + 40, 0, '', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		var blackBorder = new FunkinSprite(-30, FlxG.height + 40);
		blackBorder.makeSolid((Std.int(FlxG.width * 1.1)),Std.int(versionShit.height + 600),FlxColor.BLACK);
		blackBorder.alpha = 0.5;

		add(blackBorder);
		add(versionShit);

		FlxTween.tween(versionShit,{y: FlxG.height - 18},2,{ease: FlxEase.elasticInOut});
		FlxTween.tween(blackBorder,{y: FlxG.height - 18},2, {ease: FlxEase.elasticInOut});

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (acceptInput) {
			if (controls.BACK) FlxG.switchState(new states.MainMenuState());

			if (FlxG.keys.justPressed.UP)
				changeSelection(-1);
			if (FlxG.keys.justPressed.DOWN)
				changeSelection(1);
			
			if (controls.ACCEPT) {
				acceptInput = false;
				switch (curSelected) {
					case 0: 
						FlxG.switchState(new ChartingState());
					case 1: 
						FlxG.switchState(new CharacterSelect());
				}
			}
		}
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound("scrollMenu"), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		switch (curSelected) {
			case 0: 
				versionShit.text = 'With this you can chart your songs.';
			case 1: 
				versionShit.text = 'With this you can edit the offsets of your characters.';
		}

		var bullShit:Int = 0;
		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = item.targetY == 0? 1 : 0.6;
		}
	}
}
