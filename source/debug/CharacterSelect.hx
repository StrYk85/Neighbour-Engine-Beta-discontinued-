package debug;

import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import play.ui.HealthIcon;
import ui.Alphabet;
import debug.DebugMenu;

using StringTools;

class CharacterSelect extends ui.MusicBeatState
{
	var characters:Array<String> = [];

	var selector:FlxText;
	var curSelected:Int = 0;

	private var grpCharacters:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		var charList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		for (char in charList) characters.push(char);

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image("mainmenu/menuDesat"));

		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		for (i => char in characters)
		{
			var charName = StringTools.replace(char, '-', ' ');
			var name:Alphabet = new Alphabet(0, (70 * i) + 30, char, true, false);
			name.isMenuItem = true;
			name.targetY = i;
			grpCharacters.add(name);

			var icon:HealthIcon = new HealthIcon(char);
			icon.sprTracker = name;

			iconArray.push(icon);
			add(icon);
		}

		add(grpCharacters);

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = controls.ACCEPT;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			if (gamepad.justPressed.DPAD_UP) changeSelection(-1);
			if (gamepad.justPressed.DPAD_DOWN) changeSelection(1);
		}

		if (upP) changeSelection(-1);
		if (downP) changeSelection(1);

		if (controls.BACK) FlxG.switchState(new DebugMenu());
		if (accepted) FlxG.switchState(new AnimationDebug(characters[curSelected]));
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected += change;

		if (curSelected < 0) curSelected = characters.length - 1;
		if (curSelected >= characters.length) curSelected = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = i == curSelected? 1 : 0.6;

		var bullShit:Int = 0;
		for (item in grpCharacters.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = item.targetY == 0? 1 : 0.6;
		}
	}
}
