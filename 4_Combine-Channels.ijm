dir = getDirectory("Select the directory containing all channels");
combined = dir + File.separator + "Combined_Channels" +File.separator;
File.makeDirectory(combined);

Dialog.createNonBlocking("Select channel directories");
Dialog.addDirectory("Where are your raw GFP channel images?", " ");
Dialog.addDirectory("Where are your raw Ctnnd2 channel images?", " ");
Dialog.addDirectory("Where are your ilastik GFP channel probability images?", " ");
Dialog.addDirectory("Where are your thresholded Ctnnd2 channel images?", " ");
Dialog.show()
chan1_dir = Dialog.getString();
chan2_dir = Dialog.getString();
chan3_dir = Dialog.getString();
chan4_dir = Dialog.getString();

/*
print(chan1_dir);
print(chan2_dir);
print(chan3_dir);
print(chan4_dir);
*/

chan1_list = getFileList(chan1_dir);
chan2_list = getFileList(chan2_dir);
chan3_list = getFileList(chan3_dir);
chan4_list = getFileList(chan4_dir);

/*
Array.print(chan1_list);
Array.print(chan2_list);
Array.print(chan3_list);
Array.print(chan4_list);
*/


for (i = 0; i < chan3_list.length; i++) {
	if(endsWith(chan3_list[i], "tif")){
		open(chan3_dir + chan3_list[i]);
		name = getTitle();
		start = indexOf(name,"MAX_");
		end = indexOf(name,"_Probabilities");
		image_root = substring(name, start+4, end);
		//print(image_root);
		run("Split Channels");
		selectWindow("C2-"+name);
		run("Close");
		selectWindow("C1-"+name);
		run("Convert to Mask");
		run("Invert LUT");
		run("Analyze Particles...", "size=1000-Infinity show=Masks include");
		rename("Mask");
		selectWindow("C1-"+name);
		run("Close");
		
		channel1 = "C1-MAX_"+image_root+".tif";
		open(chan1_dir + channel1);
		
		selectWindow("Mask");
		run("16-bit");
		run("Merge Channels...", "c1=Mask c2=["+channel1+"] create");
		rename(image_root);
		
		run("Channels Tool...");
		waitForUser("Use the paintbrush and fill bucket tools to edit the mask channel. Press 'OK' when you are done editing. ");
		
		selectWindow(image_root);
		run("Split Channels");
		selectWindow("C1-"+image_root);
		rename("Channel3");
		selectWindow("C2-"+image_root);
		rename("Channel1");
		
		open(chan2_dir + "C2-MAX_" + image_root+".tif");
		rename("Channel2");
		open(chan4_dir + "Mask-C2-MAX_"+image_root+".tif");
		run("16-bit");
		rename("Channel4");
		
		run("Merge Channels...", "c1=Channel1 c2=Channel2 c3=Channel3 c4=Channel4 create");
		rename(image_root);
		
		saveAs("tiff", combined + image_root);
		run("Close All");
	}
	
}
print("Done");
