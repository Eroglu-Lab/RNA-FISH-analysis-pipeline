dir=getDirectory("Choose a Directory");  
GFP= dir +File.separator+ "GFP"+File.separator;
File.makeDirectory(GFP);
Ctnnd2= dir +File.separator+"Ctnnd2"+File.separator;
File.makeDirectory(Ctnnd2);
NeuN= dir +File.separator+"NeuN"+File.separator;
File.makeDirectory(NeuN);

list= getFileList(dir);

setBatchMode(true);

for (i = 0; i <list.length; i++) {
	if( endsWith(list[i], ".tif")) {
			open(dir + list[i]);       
			imgName=getTitle();
			run("Split Channels");
			selectWindow("C1-" + imgName);
			saveAs("tiff", GFP + "C1-" + imgName);
			selectWindow("C2-" + imgName);
			saveAs("tiff", Ctnnd2 + "C2-" + imgName);
			run("Collect Garbage");
			selectWindow("C3-" + imgName);
			saveAs("tiff", NeuN + "C3-" + imgName);
	}
	run("Close All");
}
print("Done");
 