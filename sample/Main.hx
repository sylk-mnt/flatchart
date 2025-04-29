package sample;

import flatchart.format.LegacyFormat;
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

function main() {
	FlatChart.init({
		onLog: (_, message, ?pos) -> haxe.Log.trace('FlatChart: $message', pos),
		fileSystem: new SysFileSystem(),
		formats: [new LegacyFormat()]
	});

	final wrapper = FlatChart.detectAndWrapFormat('sample/bopeebo');
	trace(wrapper.format.getName());
	trace(wrapper.charts.length);
	trace(wrapper.charts.map(chart -> '${chart.variation} ${chart.metadata.title}'));
}
