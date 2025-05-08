package chartdex.format;

import hxjsonast.Json.JsonValue;
import chartdex.Chartdex.ChartdexLogLevel;
import haxe.io.Path;
import chartdex.format.Format.FormatWrapper;
import hxjsonast.Parser;

using hxjsonast.Tools;
using StringTools;

class LegacyFormat extends Format {
	override function getName():String {
		return 'Friday Night Funkin\' Legacy/0.2.x';
	}

	override function createWrapper():LegacyFormatWrapper {
		return new LegacyFormatWrapper(this);
	}

	override function isMatch(path:String):Bool {
		if (!Chartdex.config.fileSystem.directoryExists(path))
			return false;

		final filenames = Chartdex.config.fileSystem.readDirectory(path);
		if (filenames.length == 0)
			return false;

		final prefix = Path.withoutDirectory(path);
		final defaultFile = '$prefix.json';

		if (!filenames.contains(defaultFile)
			&& !Lambda.exists(filenames, filename -> filename.startsWith('$prefix-') && filename.endsWith('.json')))
			return false;

		if (Chartdex.config.readFileContents) {
			for (filename in filenames) {
				try {
					final filepath = Path.join([path, filename]);
					final json = Parser.parse(Chartdex.config.fileSystem.getText(filepath), filepath);

					if (json.getField('song') == null)
						return false;

					final song = json.getField('song').value;

					if (song.getField('song') == null || song.getField('bpm') == null || song.getField('notes') == null)
						return false;

					final sections = song.getField('notes').value;
					if (!sections.value.match(JsonValue.JArray(_)))
						return false;

					switch sections.value {
						case JsonValue.JArray(sections):
							for (section in sections) {
								if (section.getField('lengthInSteps') == null
									|| section.getField('sectionNotes') == null
									|| section.getField('mustHitSection') == null)
									return false;
							}
						case _:
							return false;
					}
				}
				catch (error) {
					Chartdex.log(ChartdexLogLevel.ERROR, 'Error parsing $filename: $error');
					continue;
				}
			}
		}

		return true;
	}

	// TODO: Implement print
}

class LegacyFormatWrapper extends FormatWrapper {
	public function new(format:LegacyFormat) {
		super(format);
	}

	override function load(path:String):LegacyFormatWrapper {
		if (!Chartdex.config.fileSystem.directoryExists(path)) {
			Chartdex.log(ChartdexLogLevel.ERROR, 'Directory not found: $path');
			return this;
		}

		final variations = _readVariations(path);
		Chartdex.log(ChartdexLogLevel.DEBUG, 'Found variations in $path: ${variations.join(', ')}');

		for (variation in variations) {
			charts[variation] = _loadChart(path, variation);
		}

		return this;
	}

	private function _readVariations(path:String):Array<String> {
		final prefix = Path.withoutDirectory(path);

		return Chartdex.config.fileSystem.readDirectory(path)
			.filter(filename -> Chartdex.config.fileSystem.fileExists(Path.join([path, filename])))
			.map(filename -> {
				if (filename == '$prefix.json')
					return Chartdex.config.defaultVariation;
				else
					return Path.withoutExtension(filename.substr(prefix.length + 1));
			});
	}

	private function _loadChart(path:String, variation:String):Chart {
		final filepath = variation == Chartdex.config.defaultVariation ? Path.join([path, '${Path.withoutDirectory(path)}.json']) : Path.join([path, '${Path.withoutDirectory(path)}-$variation.json']);

		final json:LegacyRaw = Parser.parse(Chartdex.config.fileSystem.getText(filepath), filepath).getField('song').value.getValue();

		final result:Chart = {
			metadata: {
				title: json.song,
				artist: Chartdex.config.defaultArtist,
				album: Chartdex.config.defaultAlbum,
				charter: Chartdex.config.defaultCharter,
				bpmChanges: [
					{
						time: -1,
						bpm: json.bpm,
						beatsPerMeasure: 4,
						stepsPerBeat: 4
					}
				],
			},
			tracks: [{sound: 'Inst', startTime: 0, endTime: 0}],
			strumlines: [
				{
					position: [0.25, 50],
					scale: 1,
					alpha: 1,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: [json.player2],
					charactersPosition: 0,
					track: 1,
					cpuControlled: true
				},
				{
					position: [0.75, 50],
					scale: 1,
					alpha: 1,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: [json.player1],
					charactersPosition: 1,
					track: 1,
					cpuControlled: false
				},
				{
					position: [0.25, 50],
					scale: 1,
					alpha: 0,
					noteSpeed: json.speed,
					noteDirection: 90,
					characters: ['gf'],
					charactersPosition: 2,
					track: 1,
					cpuControlled: true
				}
			],
			notes: [],
			events: [],
			stage: null,
			extraValues: new Map<String, Dynamic>()
		}

		if (json.needsVoices)
			result.tracks.push({sound: 'Voices', startTime: 0, endTime: 0});

		var currentBPM = json.bpm;
		var currentTime = 0.0;
		var lastMustHit = false;

		for (section in json.notes) {
			if (section.changeBPM && section.bpm != currentBPM) {
				currentBPM = section.bpm;
				result.metadata.bpmChanges.push({
					time: currentTime,
					bpm: currentBPM,
					beatsPerMeasure: section.lengthInSteps * 0.25,
					stepsPerBeat: 4
				});
			}

			if (lastMustHit != section.mustHitSection) {
				lastMustHit = section.mustHitSection;
				result.events.push({
					time: currentTime,
					kind: 'Move Camera',
					data: [section.mustHitSection ? 1 : 0]
				});
			}

			for (note in section.sectionNotes) {
				var time:Float = note[0];
				var id:Int = note[1];
				var length:Float = note[2];

				var strumline = id >= 4 ? (section.mustHitSection ? 0 : 1) : (section.mustHitSection ? 1 : 0);
				id %= 4;

				result.notes.push({
					time: time,
					length: length,
					lane: id + 4 * strumline,
					kind: section.altAnim || note[3] ? 'alt-anim' : null});
			}

			currentTime += section.lengthInSteps * 60 / currentBPM * 0.25 * 1000;
		}

		Chartdex.log(ChartdexLogLevel.DEBUG, 'Loaded chart from $filepath');
		return result;
	}
}

typedef LegacyRaw = {
	var song:String;
	var notes:Array<LegacyRawSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
}

typedef LegacyRawSection = {
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}
