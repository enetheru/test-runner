@tool
extends EditorScript

var fs := EditorInterface.get_resource_filesystem()
var test_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://tests/' )
var fbs_dir : EditorFileSystemDirectory = fs.get_filesystem_path( 'res://fbs_files/tests/' )

static func test_script_filter( filename : String ) -> bool:
	return filename.begins_with("test") \
		and filename.ends_with(".gd") \
		and not filename.ends_with("_generated.gd")

static func schema_file_filter( filename : String ) -> bool:
	return filename.ends_with(".fbs")

static func folder_filter( folder_path : String ) -> bool:
	var files : Array = DirAccess.get_files_at( folder_path )
	return not files.filter( test_script_filter ).is_empty()


static func collect_tests( test_path : String ) -> Array[Dictionary]:
	var tests : Array[Dictionary]

	var folders : Array = DirAccess.get_directories_at(test_path)
	var folder_paths = folders.map(func(folder : String): return "/".join([test_path,folder]))
	folder_paths.sort()
	for folder_path : String in folder_paths.filter( folder_filter ):
		var files : Array = DirAccess.get_files_at( folder_path )
		var folder = folder_path.get_file()

		var test_dict : Dictionary = {
			"name": folder.to_pascal_case(),
			"folder_path": folder_path,
			"test_scripts": files.filter( test_script_filter ),
			"schema_files": files.filter( schema_file_filter )
		}
		tests.append( test_dict )

	return tests
