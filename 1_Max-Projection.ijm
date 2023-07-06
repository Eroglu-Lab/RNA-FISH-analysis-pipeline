dir = getDirectory("Choose");
list = getFileList(dir);
output = dir + File.separator + "Max_Projections"+File.separator;
File.makeDirectory(output);

setBatchMode(true);

for (i = 0; i < list.length; i++) {
	run("Bio-Formats Importer", "open=["+dir+list[i]+"] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	name = getTitle();
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow("MAX_"+name);
	saveAs("tiff", output + "MAX_"+name);
	run("Close All");
}
print("Done");