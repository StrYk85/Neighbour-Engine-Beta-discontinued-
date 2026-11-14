package backend.utils;

class WindowUtil {
    public static function changeWindowTitle(newTitle:String):Void {
        lime.app.Application.current.window.title = newTitle;
    }

    public static function addToWindowTitle(newTitle:String):Void {
        lime.app.Application.current.window.title += newTitle;
    }

    public static function resetWindowTitle():Void {
        lime.app.Application.current.window.title = Defaults.WINDOW_TITLE;
    }

    public static function fancyOpenURL(schmancy:String):Void {
		#if linux
		Sys.command('/usr/bin/xdg-open', [schmancy, "&"]);
		#else
		FlxG.openURL(schmancy);
		#end
	}

	public static function setupDarkWindow() {
        #if(cpp && windows)
        hxwindowmode.WindowColorMode.setWindowColorMode(true);
        hxwindowmode.WindowColorMode.redrawWindowHeader();
        #end
    }
}