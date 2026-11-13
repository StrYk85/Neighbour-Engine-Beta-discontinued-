package play.ui;

import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import ui.DefaultText;

class HealthBar extends flixel.group.FlxSpriteGroup {
    public var barBG:FlxSprite;
	public var bar:FlxBar;
    public var txt:DefaultText;

    public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

    public function new(parent:Dynamic, variable:String, min:Float, max:Float, ?info, ?reversed:Bool = false) {
        super();

        barBG = new FlxSprite().loadGraphic(Paths.image('healthBar'));
		barBG.scrollFactor.set();
        
		bar = new FlxBar(barBG.x + 4, barBG.y + 4, RIGHT_TO_LEFT, Std.int(barBG.width - 8), Std.int(barBG.height - 8), parent, variable, min, max);
        bar.flipX = reversed;
		bar.scrollFactor.set();
		bar.createFilledBar(
            FlxColor.fromString(info.iconP2Color) ?? backend.Defaults.OPPONENT_COLOR, 
            FlxColor.fromString(info.iconP1Color) ?? backend.Defaults.PLAYER_COLOR
        );
		add(bar);
        add(barBG);

        iconP1 = new HealthIcon(info.iconP1 ?? backend.Defaults.DEFAULT_ICON_ID, !reversed);
		iconP1.y = bar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(info.iconP2 ?? backend.Defaults.DEFAULT_ICON_ID, reversed);
		iconP2.y = bar.y - (iconP2.height / 2);
		add(iconP2);

        txt = new DefaultText();
        txt.x = Std.int(barBG.x + (barBG.width - txt.width) / 2);
        txt.y = barBG.y + 50;
		txt.scrollFactor.set();
        add(txt);
    }

    override function update(elapsed:Float) {
        txt.x = Std.int(barBG.x + (barBG.width - txt.width) / 2);

        for (icon in [iconP1, iconP2]) {
            icon.setGraphicSize(FlxMath.lerp(150, icon.width, 0.75));
            icon.updateHitbox();
            
            var iconOffset = backend.Defaults.DEFAULT_ICON_OFFSET;
            var offsetSHIT:Float = icon.isPlayer? iconOffset : icon.width - iconOffset;
            icon.x = bar.x + bar.width * (FlxMath.remapToRange(bar.percent, 0, 100, bar.flipX? 0 : 100, bar.flipX? 100 : 0) * 0.01) - offsetSHIT;
            icon.y = bar.y + (bar.height - icon.height) / 2 - 5;

            icon.percent = bar.percent;
        }
        super.update(elapsed);
    }
}