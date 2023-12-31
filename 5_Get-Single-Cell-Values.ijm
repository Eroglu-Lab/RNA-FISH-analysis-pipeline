/* Before using this script.  Test it out on a few images to make sure your system is taking the correct value for the selection not the inverse selection.*/

dir = getDirectory("Choose directory containing your images post-segmentation:");
list = getFileList(dir);
mask_chan = getNumber("In which Channel is your segmentation mask in?", 4);
cutoff = getNumber("Input the smallest area in pixels to accept as a cell.", 1000);
overlays = dir + File.separator + "Overlays" + File.separator;
File.makeDirectory(overlays);

setBatchMode(false);

for (i = 0; i < list.length; i++) {
	if(endsWith(list[i], ".tif")){
		img_name = open_img(dir+list[i]);
		getDimensions(width, height, channels, slices, frames);
		cell_outline(mask_chan,img_name, i);
		merge_chan(channels, mask_chan);
		setBatchMode(false);
		cell_folder = iterate_roi(overlays, img_name);
		get_data_cells(cell_folder, overlays, mask_chan);
	}
}


function open_img(img){
	/* As you would expect, this function is just to open the image and get some basic information about it.
	 */
		run("Bio-Formats Importer", "open=["+img+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		img_name = getTitle();
		return img_name;
}


function cell_outline(mask_chan,img_name, i){
	/* This function is to generate both an outline ROI for each cell and a binary mask for each cell.  
	 *  The hope is to eventually iterate over these binary masks rather than the ROIs because FIJI doesn't create ROIs with holes.
	 *  By that I mean each ROI includes the holes generated by overlapping branches.  To get around this I will have the script create selections from the binary images alone.
	 */
	if( i > 0){
		//run("ROI Manager...");
		roi_count = roiManager("count");
		if(roi_count > 0){
			roiManager("Deselect");
			roiManager("Delete");
			run("Split Channels");
			selectWindow("C"+mask_chan+"-"+img_name);
			run("Invert");
			
			//setAutoThreshold("Intermodes dark"); /* On windows, this worked, but for mac I switched it back to just intermodes because it wasn't working for some strange reason.*/
			setAutoThreshold("Intermodes");
			
			run("Threshold...");
			
			//waitForUser("Threshold UNet Mask", "Threshold your UNet mask and click 'OK' to continue");
			//cutoff = 850;//getNumber("Input the smallest area in pixels to accept as a cell.", 1500);
			
			run("Analyze Particles...", "size=["+cutoff+"]-Infinity show=Masks exclude add");
		}
		else{
			run("Split Channels");
			selectWindow("C"+mask_chan+"-"+img_name);
			run("Invert");
					
			//setAutoThreshold("Intermodes dark"); /* On windows, this worked, but for mac I switched it back to just intermodes because it wasn't working for some strange reason.*/
			setAutoThreshold("Intermodes");
			
			run("Threshold...");
			
			//waitForUser("Threshold UNet Mask", "Threshold your UNet mask and click 'OK' to continue");
			//cutoff = 850;//getNumber("Input the smallest area in pixels to accept as a cell.", 1500);
			
			run("Analyze Particles...", "size=["+cutoff+"]-Infinity show=Masks exclude add");
		}
	}
	else{
		run("Split Channels");
		selectWindow("C"+mask_chan+"-"+img_name);
		run("Invert");
			
		//setAutoThreshold("Intermodes dark"); /* On windows, this worked, but for mac I switched it back to just intermodes because it wasn't working for some strange reason.*/
		setAutoThreshold("Intermodes");
			
		run("Threshold...");
		
		//waitForUser("Threshold UNet Mask", "Threshold your UNet mask and click 'OK' to continue");
		//cutoff = 850;//getNumber("Input the smallest area in pixels to accept as a cell.", 1500);
		
		run("Analyze Particles...", "size=["+cutoff+"]-Infinity show=Masks exclude add");
	}
}

function merge_chan(channels, mask_chan){
	/* In these lines I am combining the image back to the way it was before.
	 *  I will do this by just merging the channels as before with the mask channel in the final position.
	 *  Later in the scripts I will have it ask which channels to take measurements for. 
	 */
	selectWindow("C"+mask_chan+"-"+img_name);
	run("Close");
	selectWindow("Mask of C"+mask_chan+"-"+img_name);
	rename("Mask");
	
	if(channels == 2){
		chan1 = "C1-"+img_name;
		chan2 = "Mask";
		selectWindow(chan1);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan2);
		run("8-bit");
		run("Merge Channels...", "c1=["+chan1+"] c2=["+chan2+"] create");
	}
	if(channels == 3){
		chan1 = "C1-"+img_name;
		chan2 = "C2-"+img_name;
		chan3 = "Mask";
		selectWindow(chan1);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan2);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan3);
		run("8-bit");
		run("Merge Channels...", "c1=["+chan1+"] c2=["+chan2+"] c3=["+chan3+"] create");
	}
	if(channels == 4){
		chan1 = "C1-"+img_name;
		chan2 = "C2-"+img_name;
		chan4 = "C4-"+img_name;
		chan3 = "Mask";
		selectWindow(chan1);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan2);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan3);
		run("16-bit");
		selectWindow(chan4);
		run("16-bit");
		run("Merge Channels...", "c1=["+chan1+"] c2=["+chan2+"] c3=["+chan3+"] c4=["+chan4+"] create");
	}
	if(channels == 5){
		chan1 = "C1-"+img_name;
		chan2 = "C2-"+img_name;
		chan3 = "C3-"+img_name;
		chan4 = "C4-"+img_name;
		chan5 = "Mask";
		selectWindow(chan1);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan2);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan3);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan4);
		run("Subtract Background...", "rolling=50");
		selectWindow(chan5);
		run("8-bit");
		run("Merge Channels...", "c1=["+chan1+"] c2=["+chan2+"] c3=["+chan3+"] c4=["+chan4+"] c5=["+chan5+"] create");
	}
	if(channels > 5){
		print("Error: Too many channels in image.");
	}
}

function iterate_roi(dir, img_name){
	/* The goal of this function is to iterate through all of the ROIs made and create images that isolate just the cell of interest.
	 *  These images are then saved in a folder that is named after the original larger image.
	 */
	numROIs = roiManager("Count");
	folder = dir + "//" + substring(img_name,0, (lengthOf(img_name)-4)) + "//";
	print(folder);
	File.makeDirectory(folder);
	
	for(i = 0; i< numROIs; i++){
		roiManager("select", i);
		roiManager("rename", "Cell_" + i+1 );
		cell = "Cell_"+i+1;
		run("Duplicate...", "duplicate");
		run("Clear Outside");
		
		rename(cell);
		selectWindow(cell);
		saveAs("tiff", folder + cell);
		selectWindow(cell+".tif");
		run("Close");
	}
	return folder;
}

function get_data_cells(cell_folder, dir, mask_chan){
	/*The goal of this function is to extract the relevant data from the single cells you are interested in.
	 *
	 */
	img_name_string = split(substring(cell_folder,0,lengthOf(cell_folder)-1),"//");
	cell_results = img_name_string[lengthOf(img_name_string)-1]+ ".csv";
	
	COI = "4";//getString("Which channels are you interested in measuring? (If multiple channels, please separate them using ';;'.", "4");
	//waitForUser("Please select the measurements you want to take for each cell in the next window. Press 'OK' to continue.");
	run("Set Measurements...", "area mean min centroid integrated display redirect=None decimal=3");
	//run("Set Measurements...");
	list_cell = getFileList(cell_folder);
	for (i = 0; i < list_cell.length; i++) {
		if(endsWith(list_cell[i], ".tif")){
			open(cell_folder+list_cell[i]);
			single_cell = getTitle();
			selectWindow(single_cell);
			run("Clear Outside");
			run("Split Channels");
			selectWindow("C"+mask_chan+"-"+single_cell);
			run("8-bit");
			run("Create Selection");
			//run("Make Inverse");
			run("Measure");
			
			//run("Make Inverse"); //This will matter more if you are running on Mac vs. PC.
			/*
			//This chunk is for troubleshooting only. 
			run("Clear");
			waitForUser("Did the inside of the cell disappear? If yes, then you have the correct selection. If not, then you need to invert your selection.");
			//
			*/
			
			if(lengthOf(COI) > 1){
				COIs = split(COI, ";;");
				for (n = 0; n < COIs.length; n++) {
					selectWindow("C"+COIs[n]+"-"+single_cell);
					run("Convert to Mask");
					run("Create Selection");
					run("Make Inverse");
					//run("Restore Selection");
					run("Measure");
					/*
					//This chunk is for troubleshooting only. 
					run("Clear");
					waitForUser("Did the inside of the cell disappear? If yes, then you have the correct selection. If not, then you need to invert your selection.");
					//
					*/
					//selectWindow("C"+COIs[n]+"-"+single_cell);
				}
				saveAs("Results", cell_folder + cell_results);
				run("Close All");
			}
			else{
				selectWindow("C"+COI+"-"+single_cell);
				run("Convert to Mask");
				run("Create Selection");
				//run("Make Inverse");
				//run("Restore Selection");
				run("Measure");
				/*
				//This chunk is for troubleshooting only. 
				run("Clear");
				waitForUser("Did the inside of the cell disappear? If yes, then you have the correct selection. If not, then you need to invert your selection.");
				//
				*/
				
				saveAs("Results", cell_folder + cell_results);
				run("Close All");
			}
		}
	}
	run("Clear Results");
	roiManager("Deselect");
	roiManager("Delete");
}
print("Done");
