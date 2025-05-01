package chartdex;

import haxe.PosInfos;
import chartdex.format.Format;
import chartdex.fs.IFileSystem;

@:structInit class ChartdexConfig {
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
	public var onLog:(ChartdexLogLevel, String, ?PosInfos) -> Void = (_, _, ?_) -> {};

	/**
	 * Minimum log level to call the `onLog` callback.
	 */
	public var logLevel:ChartdexLogLevel = ChartdexLogLevel.WARNING;

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

class Chartdex {
	/**
	 * Library configuration.
	 */
	public static var config:ChartdexConfig;

	/**
	 * Detects the format of a chart.
	 * @param path - The path to scan.
	 * @return The format.
	 */
	public static function detectFormat(path:String):Null<Format> {
		if (config == null)
			throw 'Chartdex not configured';

		log(ChartdexLogLevel.NOTICE, 'Detecting format for $path');
		for (format in config.formats) {
			if (format.isMatch(path)) {
				log(ChartdexLogLevel.NOTICE, 'Format detected for $path: ${format.getName()}');
				return format;
			}
		}
		log(ChartdexLogLevel.ERROR, 'Format not detected for $path');
		return null;
	}

	/**
	 * Wraps a format in a wrapper.
	 * @param path - The path to scan.
	 * @param format - The format to wrap.
	 * @return The wrapped format.
	 */
	public static inline function wrapFormat(path:String, format:Format):FormatWrapper {
		if (config == null)
			throw 'Chartdex not configured';

		return format.createWrapper().load(path);
	}

	/**
	 * Detects the format of a chart and wraps it.
	 * If the format is not detected, returns `null`.
	 * @param path - The path to scan.
	 * @return The wrapped format.
	 */
	public static inline function detectAndWrapFormat(path:String):Null<FormatWrapper> {
		if (config == null)
			throw 'Chartdex not configured';

		final format = detectFormat(path);
		if (format == null)
			return null;

		return wrapFormat(path, format);
	}

	/**
	 * Logs a message.
	 * @param level - The log level.
	 * @param message - The message to log.
	 * @param pos - The position of the message.
	 */
	public static function log(level:ChartdexLogLevel, message:String, ?pos:PosInfos) {
		if (config == null)
			throw 'Chartdex not configured';

		if ((level : Int) < (config.logLevel : Int))
			return;

		if (config.onLog != null)
			config.onLog(level, message, pos);
	}
}

enum abstract ChartdexLogLevel(Int) to Int {
	var DEBUG = 0;
	var NOTICE = 1;
	var WARNING = 2;
	var ERROR = 3;
}
