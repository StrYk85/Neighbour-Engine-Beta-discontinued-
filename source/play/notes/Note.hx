package play.notes;

class Note extends flixel.FlxSprite {
	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public var prevNote:Note;
	public var nextNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var sustainParent:Bool = false;

	public var hasBeenMissed:Bool = false;

	public var noteScore:Float = 1;
	public var noteScale:Float = 1;
	public var rating:String = "shit";

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inCharter:Bool = false) {
		super();
		if (prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		y = -FlxG.height * 1.5;
		this.strumTime = Math.max(inCharter? strumTime : Math.round(strumTime), 0);
		this.noteData = noteData;
		flipY = FlxG.save.data.downscroll && isSustainNote;

		//defaults if no noteStyle was found in chart
		var noteTypeCheck:String = 'default';
		NoteStyle.applyToNote(this, noteTypeCheck);

		if (isSustainNote && prevNote != null) {
			noteScore = flixel.math.FlxMath.roundDecimal(noteScore * 0.2, 2);
			animation.play('holdend');
			updateHitbox();

			if (!prevNote.isSustainNote) 
				prevNote.sustainParent = true;
			else {
				prevNote.animation.play('hold');
				prevNote.scale.y = noteScale * Conductor.stepCrochet / 100 * 1.5 * (FlxG.save.data.scrollSpeed != 1? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
				prevNote.updateHitbox();
			}
		}
		else
			animation.play('scroll');
	}

	public function updateNote(isBot:Bool) {
		if (!isBot) {
			var zoneOffsetThingy = isSustainNote? Conductor.safeZoneOffset * 0.5 : Conductor.safeZoneOffset;
			canBeHit = strumTime > Conductor.songPosition - Conductor.safeZoneOffset && strumTime < Conductor.songPosition + zoneOffsetThingy;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale && !wasGoodHit) tooLate = true;
		}
		else {
			canBeHit = false;
			wasGoodHit = strumTime <= Conductor.songPosition;
		}

		if (tooLate && alpha > 0.3) alpha = 0.3;
	}
}