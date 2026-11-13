package graphics;

import flixel.util.FlxColor;

class DynamicBackground extends flixel.group.FlxSpriteGroup {
    public var bgBlank:FunkinSprite;
	public var bgOutline:FunkinSprite;

    public static var selectedColors:Array<Array<FlxColor>> = [[0xFFFDE871, 0xFFDC7727],[0xFFFD719B, 0xFFDD29A7]];
    public function new() {
        super();
		bgOutline = new FunkinSprite();
        bgOutline.antialiasing = true;
		bgOutline.loadGraphic(Paths.image('mainmenu/menuOutline'));

        bgBlank = new FunkinSprite();
		bgBlank.makeSolid(1, 1, 0xFFFFFFFF);
        setScale(1, 1);
        setSelectedColor(0);

		add(bgBlank);
		add(bgOutline);
    }

    public function setScale(scaleX:Float = 1, ?scaleY:Null<Float>) {
        if (scaleY == null) bgOutline.setGraphicSize(Std.int(bgOutline.width * scaleX));
        else bgOutline.setGraphicSize(Std.int(bgOutline.width * scaleX), Std.int(bgOutline.height * scaleY));
        bgOutline.updateHitbox();

        bgBlank.scale.set(bgOutline.width, bgOutline.height);
        bgBlank.updateHitbox();
    }

    public function setColor(col1:FlxColor, col2:FlxColor) {
        bgBlank.color = col1;
		bgOutline.color = col2;
    }

    public function setSelectedColor(colID:Int) {
        setColor(selectedColors[colID][0], selectedColors[colID][1]);
    }
}