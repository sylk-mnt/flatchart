package flatchart.fs;

import haxe.io.Bytes;
#if !sys
import flatchart.FlatChart.FlatChartLogLevel;
class SysFileSystem implements IFileSystem {
	public function new() {
		FlatChart.log(FlatChartLogLevel.Error, 'Sys required to use SysFileSystem');
	}

	public function readDirectory(path:String):Array<String> {
		return [];
	}

	public function getBytes(path:String):Null<Bytes> {
		return null;
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

	public function directoryExists(path:String):Bool {
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}

	public function fileExists(path:String):Bool {
		return FileSystem.exists(path) && !FileSystem.isDirectory(path);
	}

	public function readDirectory(path:String):Array<String> {
		if (!directoryExists(path))
			return [];

		return FileSystem.readDirectory(path);
	}

	public function getBytes(path:String):Null<Bytes> {
		if (!fileExists(path))
			return null;

		return File.getBytes(path);
	}
}
#end
