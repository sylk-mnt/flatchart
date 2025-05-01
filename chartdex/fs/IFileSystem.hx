package chartdex.fs;

import haxe.io.Bytes;

interface IFileSystem {
	public function getBytes(path:String):Null<Bytes>;
	public function getText(path:String):Null<String>;
	public function readDirectory(path:String):Array<String>;
	public function directoryExists(path:String):Bool;
	public function fileExists(path:String):Bool;
}
