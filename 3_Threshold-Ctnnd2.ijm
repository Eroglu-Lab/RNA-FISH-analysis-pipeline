dir = getDirectory("Choose channel to process");
list = getFileList(dir);
output = dir + File.separator + "Thresholded-Ctnnd2" + File.separator;
File.makeDirectory(output);

for (i = 0; i < list.length; i++) {
	if(endsWith(list[i],"tif")){
		open(dir + list[i]);
		name = getTitle();
		run("Subtract Background...", "rolling=50");
		run("Gaussian Blur...", "sigma=0.57");
		
		run("Threshold...");
		waitForUser("Threshold the image and press 'OK' when ready");
		run("Convert to Mask");
		saveAs("tiff", output + "Mask-" + name);
		run("Close All");
	}
}
print("Done");