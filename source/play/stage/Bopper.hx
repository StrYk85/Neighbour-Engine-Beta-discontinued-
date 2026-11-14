package play.stage;

class Bopper extends graphics.FunkinSprite {
    public var shouldAlternate:Bool = false;
    public var alternated:Bool = false;
    public var name:String = '';

    public var logicUpdate:Bool = true;
    public function new (?x:Float = 0, ?y:Float = 0, ?name:String = null) {
        super(x, y);
        this.name ??= name;
    }

    public function dance(force:Bool = false) {
        if (!logicUpdate) return;
        if (shouldAlternate) {
            playAnim(alternated? 'danceRight' : 'danceLeft', force);
            alternated = !alternated;
        }
        else 
            playAnim('idle', force);
    }
}