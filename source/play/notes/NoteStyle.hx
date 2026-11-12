package play.notes;

import flixel.FlxSprite;
using StringTools;

class NoteStyle {
    private static final daPixelZoom:Float = 6;
    private static final defaultZoom:Float = 0.7;

    public static function applyToNote(obj:Note, ?noteStyle:String):Void {
        var zoomToUse:Float = defaultZoom;
        switch (noteStyle) {
            case 'pixel':
				if (obj.isSustainNote) {
					obj.loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);
					obj.animation.add('holdend', [obj.noteData + 4]);
					obj.animation.add('hold', [obj.noteData]);
				}
                else {
                    obj.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
                    obj.animation.add('scroll', [obj.noteData + 4]);
                }

                zoomToUse = daPixelZoom;
            default:
                obj.frames = Paths.getSparrowAtlas('notestyles/default/NOTE_assets');
				var colors = backend.Defaults.NOTE_COLOR_NAMES;
                if (obj.isSustainNote) {
                    obj.animation.addByPrefix('hold', colors[obj.noteData].toLowerCase() + ' hold piece');
                    obj.animation.addByPrefix('holdend', colors[obj.noteData].toLowerCase() + ' hold end');
                    obj.alpha = 0.8;
                }
                else
                    obj.animation.addByPrefix('scroll', colors[obj.noteData].toLowerCase() + '0');
        }

        obj.setGraphicSize(Std.int(obj.width * zoomToUse));
        obj.updateHitbox();
        obj.noteScale = zoomToUse;
        obj.antialiasing = noteStyle != 'pixel';
    }

    public static function applyToStrumNote(obj:FlxSprite, direction:Int, ?noteStyle:String):Void {
        var zoomToUse:Float = defaultZoom;
        switch (noteStyle) {
            case 'pixel': 
                obj.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
                obj.animation.add('static', [direction]);
				obj.animation.add('pressed', [direction + 4, direction + 8], 12, false);
				obj.animation.add('confirm', [direction + 12, direction + 16], 24, false);

                zoomToUse = daPixelZoom;
            default:
                var noteDirections = backend.Defaults.NOTE_DIRECTIONS;
                obj.frames = Paths.getSparrowAtlas('notestyles/default/NOTESTRUMLINE_assets');
                obj.animation.addByPrefix('static', 'arrow' + noteDirections[direction].toUpperCase());
                obj.animation.addByPrefix('pressed', noteDirections[direction].toLowerCase() + ' press', 24, false);
                obj.animation.addByPrefix('confirm', noteDirections[direction].toLowerCase() + ' confirm', 24, false);
        }

        obj.setGraphicSize(Std.int(obj.width * zoomToUse));
        obj.updateHitbox();
        obj.antialiasing = noteStyle != 'pixel';
    }
}