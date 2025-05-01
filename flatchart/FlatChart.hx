package flatchart;

import haxe.PosInfos;
import flatchart.format.Format;
import flatchart.fs.IFileSystem;

@:structInit class FlatChartConfig {
	/**
	 * Default title for the chart. Used when no title is specified.
	 */
	public var defaultTitle:String = 'Untitled';

	/**
	 * Default artist name for the chart. Used when no artist is specified.
	 */
	public var defaultArtist:String = 'Unknown Artist';

	/**
	 * Default album name for the chart. Used when no album is specified.
	 */
	public var defaultAlbum:String = 'Unknown Album';

	/**
	 * Default charter name. Used when no charter is specified.
	 */
	public var defaultCharter:String = 'Unknown Charter';

	/**
	 * Default variation/difficulty name.
	 */
	public var defaultVariation:String = 'normal';

	/**
	 * Callback function for logging events.
	 * Takes a log level and message as parameters.
	 */
	public var onLog:(FlatChartLogLevel, String, ?PosInfos) -> Void = (_, _, ?_) -> {};

	/**
	 * Minimum log level to call the `onLog` callback.
	 */
	public var logLevel:FlatChartLogLevel = FlatChartLogLevel.WARNING;

	/**
	 * File system instance.
	 */
	public var fileSystem:IFileSystem;

	/**
	 * List of formats to use.
	 */
	public var formats:Array<Format> = [];

	/**
	 * Whether to read the file contents of the chart for high detection accuracy.
	 */
	public var readFileContents:Bool = false;
}

class FlatChart {
	public static var config:FlatChartConfig;

	public static function init(config:FlatChartConfig) {
		FlatChart.config = config;
	}

	public static function detectFormat(path:String):Null<Format> {
		log(FlatChartLogLevel.INFO, 'Detecting format for $path');
		for (format in config.formats) {
			if (format.isMatch(path)) {
				log(FlatChartLogLevel.INFO, 'Format detected for $path: ${format.getName()}');
				return format;
			}
		}
		log(FlatChartLogLevel.ERROR, 'Format not detected for $path');
		return null;
	}

	public static inline function wrapFormat(path:String, format:Format):FormatWrapper {
		return format.createWrapper().load(path);
	}

	public static inline function detectAndWrapFormat(path:String):Null<FormatWrapper> {
		final format = detectFormat(path);
		if (format == null)
			return null;

		return wrapFormat(path, format);
	}

	public static function log(level:FlatChartLogLevel, message:String, ?pos:PosInfos) {
		if ((level : Int) < (config.logLevel : Int))
			return;

		if (config.onLog != null)
			config.onLog(level, message, pos);
	}
}

enum abstract FlatChartLogLevel(Int) to Int {
	var DEBUG = 0;
	var INFO = 1;
	var WARNING = 2;
	var ERROR = 3;
}
