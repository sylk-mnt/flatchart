package chartdeck.fs;

import haxe.io.Bytes;
#if !lime
import flatchart.FlatChart.FlatChartLogLevel;
class LimeFileSystem implements IFileSystem {
	public function new() {
		FlatChart.log(FlatChartLogLevel.Error, 'Lime required to use LimeFileSystem');
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
import lime.utils.Assets;
import haxe.io.Path;

using StringTools;

class LimeFileSystem implements IFileSystem {
	public function new() {}

	public function readDirectory(path:String):Array<String> {
		path = Path.addTrailingSlash(path);
		#if sys
		path = Path.normalize(sys.FileSystem.absolutePath(path));
		#end

		final assetIds = Assets.list().filter(assetId -> Assets.getPath(assetId).startsWith(path));

		final result:Array<String> = [];
		for (assetId in assetIds) {
			final assetPath = Assets.getPath(assetId);
			final trimmedPath = assetPath.substring(path.length).split('/')[0];
			if (!result.contains(trimmedPath))
				result.push(trimmedPath);
		}
		return result;
	}

	public function getBytes(path:String):Null<Bytes> {
		if (!fileExists(path))
			return null;

		return Assets.getBytes(path);
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
