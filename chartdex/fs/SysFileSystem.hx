package chartdex.fs;

import chartdex.Chartdex.ChartdexLogLevel;
import haxe.io.Bytes;
#if !sys
class SysFileSystem implements IFileSystem {
	public function new() {
		Chartdex.log(ChartdexLogLevel.ERROR, 'Sys required to use SysFileSystem');
	}

	public function getBytes(path:String):Null<Bytes> {
		return null;
	}

	public function getText(path:String):Null<String> {
		return null;
	}

	public function readDirectory(path:String):Array<String> {
		return [];
	}

	public function directoryExists(path:String):Bool {
		return false;
	}

	public function fileExists(path:String):Bool {
		return false;
	}
}
#else
import sys.io.File;
import sys.FileSystem;

class SysFileSystem implements IFileSystem {
	public function new() {}

	public function getBytes(path:String):Null<Bytes> {
		if (!fileExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, '$path does not exist');
			return null;
		}

		return File.getBytes(path);
	}

	public function getText(path:String):Null<String> {
		if (!fileExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, '$path does not exist');
			return null;
		}

		return File.getContent(path);
	}

	public function readDirectory(path:String):Array<String> {
		if (!directoryExists(path))
			return [];

		return FileSystem.readDirectory(path);
	}

	public function directoryExists(path:String):Bool {
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}

	public function fileExists(path:String):Bool {
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);
	}
}
#end
