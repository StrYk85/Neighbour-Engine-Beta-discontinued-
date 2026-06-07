package ui;

import flixel.text.FlxBitmapText;
import flixel.text.FlxBitmapFont;

class DefaultText extends FlxBitmapText {
    public function new(x:Float = 0, y:Float = 0, txt:String = '', border:Bool = true) {
        super(x, y, txt, FlxBitmapFont.fromAngelCode(Paths.font("vcr-bmp.png"), Paths.font("vcr-bmp.fnt")));
        if (border) {
            this.borderStyle = OUTLINE;
            this.borderColor = 0xFF000000;
        }
        this.letterSpacing = -1;
        //this.setFormat('VCR OSD Mono', size, 0xFFFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        //this.scrollFactor.set(0, 0);
        //this.antialiasing = true;
    }
}