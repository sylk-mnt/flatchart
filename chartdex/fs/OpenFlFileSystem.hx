package chartdex.fs;

import chartdex.Chartdex.ChartdexLogLevel;
import haxe.io.Bytes;
#if !openfl
class OpenFlFileSystem implements IFileSystem {
	public function new() {
		Chartdex.log(ChartdexLogLevel.ERROR, 'OpenFL required to use OpenFlFileSystem');
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
import openfl.Assets;
import haxe.io.Path;

using StringTools;

class OpenFlFileSystem implements IFileSystem {
	public function new() {}

	public function getBytes(path:String):Null<Bytes> {
		if (!fileExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, '$path does not exist');
			return null;
		}

		return Assets.getBytes(path);
	}

	public function getText(path:String):Null<String> {
		if (!fileExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, '$path does not exist');
			return null;
		}

		return Assets.getText(path);
	}

	public function readDirectory(path:String):Array<String> {
		path = Path.addTrailingSlash(path);

		final assetIds = Assets.list().filter(assetId -> assetId.startsWith(path));

		final result:Array<String> = [];
		for (assetId in assetIds) {
			final trimmedPath = assetId.substring(path.length).split('/')[0];
			if (!result.contains(trimmedPath))
				result.push(trimmedPath);
		}
		return result;
	}

	public function directoryExists(path:String):Bool {
		path = Path.addTrailingSlash(path);
		#if sys
		path = Path.normalize(sys.FileSystem.absolutePath(path));
		#end

		return Assets.list().filter(assetId -> Assets.getPath(assetId).startsWith(path)).length > 0;
	}

	public function fileExists(path:String):Bool {
		return Assets.exists(path);
	}
}
#end
