package flatchart.format;

import flatchart.FlatChart.FlatChartLogLevel;
import haxe.io.Path;
import flatchart.format.Format;
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
		if (!FlatChart.config.fileSystem.directoryExists(path))
			return false;

		final filenames = FlatChart.config.fileSystem.readDirectory(path);
		if (filenames.length == 0)
			return false;

		final prefix = Path.withoutDirectory(path);
		final defaultFile = '$prefix.json';

		if (!filenames.contains(defaultFile)
			&& !Lambda.exists(filenames, filename -> filename.startsWith('$prefix-') && filename.endsWith('.json')))
			return false;

		if (FlatChart.config.highDetectionAccuracy) {
			for (filename in filenames) {
				try {
					final json = Parser.parse(FlatChart.config.fileSystem.getBytes(Path.join([path, filename])).toString(), filename);

					if (json.getField('song') == null)
						return false;

					final song = json.getField('song').value;

					if (song.getField('song') == null || song.getField('bpm') == null || song.getField('notes') == null)
						return false;

					final sections = song.getField('notes').value;
					if (!sections.value.match(JArray(_)))
						return false;

					switch sections.value {
						case JArray(sections):
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
					FlatChart.log(FlatChartLogLevel.Error, 'Error parsing $filename: $error');
					continue;
				}
			}
		}

		return true;
	}
}

class LegacyFormatWrapper extends FormatWrapper {
	override function load(path:String):LegacyFormatWrapper {
		if (!FlatChart.config.fileSystem.directoryExists(path)) {
			FlatChart.log(FlatChartLogLevel.Error, 'Directory not found: $path');
			return this;
		}

		final variations = _readVariations(path);
		FlatChart.log(FlatChartLogLevel.Info, 'Found variations in $path: ${variations.join(', ')}');

		// TODO: Load metadata

		for (variation in variations) {
			final chart = _loadChart(path, variation);
			if (chart == null) {
				FlatChart.log(FlatChartLogLevel.Error, 'Failed to load chart for variation $variation');
				continue;
			}
			charts.push(chart);

			if (variation == FlatChart.config.defaultVariation)
				metadata = chart.metadata;
		}

		return this;
	}

	private function _readVariations(path:String):Array<String> {
		final prefix = Path.withoutDirectory(path);

		return FlatChart.config.fileSystem.readDirectory(path)
			.filter(filename -> FlatChart.config.fileSystem.fileExists(Path.join([path, filename])))
			.map(filename -> {
				if (filename == '$prefix.json')
					return FlatChart.config.defaultVariation;
				else
					return Path.withoutExtension(filename.substr(prefix.length + 1));
			});
	}

	private function _loadChart(path:String, variation:String):FormatChart {
		final filepath = variation == FlatChart.config.defaultVariation ? Path.join([path, '${Path.withoutDirectory(path)}.json']) : Path.join([path, '${Path.withoutDirectory(path)}-$variation.json']);

		final json:LegacyRaw = Parser.parse(FlatChart.config.fileSystem.getBytes(filepath).toString(), filepath).getField('song').value.getValue();

		final result:FormatChart = {
			variation: variation,
			metadata: {
				title: json.song,
				artist: FlatChart.config.defaultArtist,
				album: FlatChart.config.defaultAlbum,
				charter: FlatChart.config.defaultCharter,
				bpmChanges: [
					{
						time: 0,
						bpm: json.bpm,
						beatsPerMeasure: 4,
						stepsPerBeat: 4
					}
				],
			},
			tracks: [{sound: 'Inst', startTime: 0, endTime: 0}],
			strumlines: [
				{
					x: 0.25,
					scale: 1,
					alpha: 1,
					characters: [json.player2],
					charactersPosition: 0,
					cpuControlled: true
				},
				{
					x: 0.75,
					scale: 1,
					alpha: 1,
					characters: [json.player1],
					charactersPosition: 1,
					cpuControlled: false
				},
				{
					x: 0.25,
					scale: 1,
					alpha: 1,
					characters: ['gf'],
					charactersPosition: 2,
					cpuControlled: true
				}
			],
			notes: [],
			events: [],
			stage: null,
			extraData: new Map<String, Dynamic>()
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
					data: section.mustHitSection ? 1 : 0
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
					sustain: length,
					lane: id + 4 * strumline,
					kind: section.altAnim ? 'alt' : 'default'
				});
			}

			currentTime += section.lengthInSteps * 60 / currentBPM * 0.25 * 1000;
		}

		FlatChart.log(FlatChartLogLevel.Debug, 'Loaded chart from $filepath');
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
