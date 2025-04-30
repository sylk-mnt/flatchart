# FlatChart

> [!WARNING]
> This project is still in early development and hasn't been thoroughly tested yet. There may be serious bugs and issues. Pull requests and issue reports are very welcome and appreciated!

FlatChart is a library designed to work with various Friday Night Funkin' chart formats. It provides a unified wrapper interface to handle different chart formats seamlessly, with an API design inspired by [Polymod](https://github.com/larsiusprime/polymod.git).

## Features

- Support for FNF Legacy/0.2.x chart format
- Unified API for working with different chart formats
- Handles chart metadata, tracks, strumlines, notes and events
- Easy to extend with new format support
- Polymod-like interface for simple integration

## Usage

### Basic Example
```haxe
import flatchart.fs.SysFileSystem;
import flatchart.FlatChart;

FlatChart.init({
	fileSystem: new SysFileSystem(),
	formats: [new LegacyFormat()]
});

final chartPath = 'assets/data/bopeebo';
final wrapper = FlatChart.detectAndWrapFormat(chartPath, format);
```

## TODO

### Format Support
- Add support for Psych Engine format (WIP)
- Add support for Codename Engine format
- Add support for FNF Forever Engine format
- Add support for Kade Engine format
- Add support for V-Slice format

### Core Features
- Add chart conversion between formats
- Add chart optimization utilities
- Add support for HeapsFileSystem
- Add proper format detection (WIP)

### Documentation
- Add contribution guidelines
