package sample;

import flatchart.format.PsychFormat;
import flatchart.format.LegacyFormat;
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

function main() {
	FlatChart.init({
		onLog: (_, message, ?pos) -> haxe.Log.trace(message, pos),
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat(), new PsychFormat()],
		highDetectionAccuracy: true
	});

	Sys.println('');
	test('sample/bopeebo');
	Sys.println('');
	test('sample/guns');
	Sys.println('');
}

function test(path:String) {
	Sys.println('Detecting and wrapping format for $path...');
	final wrapper = FlatChart.detectAndWrapFormat(path);
	if (wrapper == null) {
		Sys.println('No format detected for $path!');
	} else {
		Sys.println('Format ${wrapper.format.getName()} detected and wrapped for $path!');
		Sys.println('\tTitle: ${wrapper.metadata.title}');
		Sys.println('\tArtist: ${wrapper.metadata.artist}');
		Sys.println('\tAlbum: ${wrapper.metadata.album}');
		Sys.println('\tBPM: ${wrapper.metadata.bpmChanges[0].bpm}');
		Sys.println('\tTime signature: ${wrapper.metadata.bpmChanges[0].beatsPerMeasure}/${wrapper.metadata.bpmChanges[0].stepsPerBeat}');

		Sys.println('\tVariations: ${wrapper.charts.map(chart -> chart.variation).join(', ')}');
		for (chart in wrapper.charts) {
			Sys.println('\t\t${chart.variation}:');
			Sys.println('\t\t\tMetadata overriden: ${chart.metadata != wrapper.metadata}');
			Sys.println('\t\t\tNotes: ${chart.notes.length}');
			Sys.println('\t\t\tEvents: ${chart.events.length}');
		}
	}
}
