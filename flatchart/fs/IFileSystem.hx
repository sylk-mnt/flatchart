package flatchart.fs;

import haxe.io.Bytes;

interface IFileSystem {
	public function getBytes(path:String):Bytes;
	public function readDirectory(path:String):Array<String>;
	public function directoryExists(path:String):Bool;
	public function fileExists(path:String):Bool;
}
