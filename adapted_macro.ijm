// NMA: Adapted from Olivier's macro here: https://github.com/engpol/JonesLabFIJIScripts/blob/main/Receptor_Expression_Macro_MESNA_MAC.ijm

//MACRO FOR DETERMINING SURFACE RECEPTOR EXPRESSION ACROSS ALL CELLS IN WELL
//GENERAL PRINCIPLE: 
// 1: SPLIT STACK IN 2: 1 FOR BRIGHTFIELD, 1 FOR FLUORESCENCE INTENSITY
// 2: RUN BASIC ON FLUORESENCE STACK TO CORRECT FOR ILLUMINATION DISCREPANCY
// 3: RUN PHANTAST ON BF TO GENERATE MASK OF CELLS
// 4. MULTIPLY FLUORESENCE STACK BY PHANTAST MASK TO GENERATE A READOUT OF AVERAGE SURFACE EXPRESSION
// 5. SAVE OUTPUT IN CSV/EXCEL FILE


//IN CASE ANY FUNCTION DOESN'T WORK BECAUSE CREATING FOLDERS INSIDE FOLDERS ALREADY CONTAINING TIFF IMAGES - - - -- -- - - - - - -- -- - - - - - -- -- -  - - - - - 
//FUNCTION TAKES AN ARRAY AND ONLY RETURNS ELEMENTS WHICH ARE TIFF IMAGES - I.E. ONLY ACCEPTS MICROSCOPY IMAGES AND IGNORES OTHER RANDOM STUFF

function ImageFilesOnlyArray (arr) {
	//pass array from getFileList through this e.g. NEWARRAY = ImageFilesOnlyArray(NEWARRAY);
	setOption("ExpandableArrays", true);
	f=0;
	files = newArray;
	for (i = 0; i < arr.length; i++) {
		if(endsWith(arr[i], ".tif") || endsWith(arr[i], ".nd2") || endsWith(arr[i], ".LSM") || endsWith(arr[i], ".czi") || endsWith(arr[i], ".jpg") ) {   //if it's a tiff image add it to the new array
			files[f] = arr[i];
			f = f+1;
		}
	}
	arr = files;
	arr = Array.sort(arr);
	return arr;
}
//- - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - - - - - -- -- - -- - - -- -- - - - - - -- -- - - - - - -- -- - -

//Parameters 
#@ File(label="Experiment folder", value = "C:/", style="directory") exfolder
#@ String (label="Segmentation Model", description="model_id field") model_id
#@ Float (label="PHANTAST Sigma", value = 4, style="spinner") sigmaint
#@ Float (label="PHANTAST Epsilon", value = 0.05, style="spinner") epsiint
#@ Integer (label="Fluorescent Channel Before Condition", value = 1, style="slider", min = 1, max = 4) flochannelbefore
#@ Integer (label="Fluorescent Channel After Condition", value = 3, style="slider", min = 1, max = 4) flochannelafter
#@ Integer (label="Brightfield Channel Before Condition", value = 2, style="slider", min = 1, max = 4) bfchannelbefore
#@ Integer (label="Brightfield Channel Before Condition", value = 4, style="slider", min = 1, max = 4) bfchannelafter


run("Fresh Start"); //ALWAYS INCLUDE
setBatchMode(true); //"TRUE" FOR FASTER PROCESSING

//Cycle through all experiments in folder
filelist = getFileList(exfolder); //Get names of all experiment folders in the main folder
for (i = 0; i < lengthOf(filelist); i++) {
    FOV_filelist = getFileList(exfolder + File.separator + filelist[i]);
    onlyimages = ImageFilesOnlyArray(FOV_filelist);
    number_of_images = lengthOf(onlyimages);
	close("*");


	//Make shared folders in current experiment folder- - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File.mkdir(exfolder + File.separator + filelist[i] + "/Brightfield_Stack"); 
	bf_dir = ""+exfolder+File.separator+filelist[i]+"Brightfield_Stack"+""; 

	File.mkdir(exfolder + File.separator + filelist[i] + "/BaSiC_Image"); 
	basic_dir = ""+exfolder+File.separator+filelist[i]+"BaSiC_Image"+""; 

	File.mkdir(exfolder + File.separator + filelist[i] + "/Segmentation_Output"); 
	segmentation_dir = ""+exfolder+File.separator+filelist[i]+"Segmentation_Output"+"";

	File.mkdir(exfolder + File.separator + filelist[i] + "/Results"); 
	results_dir = ""+exfolder+File.separator+filelist[i]+"Results"+"";
    
	// Deinterleave into 4 channels, save 1st channel of Brightfields - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File.openSequence(exfolder + File.separator + filelist[i]); //Import image sequence
	rename("expt"); 
	run("Deinterleave", "how=4"); //Split bf and fluoresence stacks
	selectImage("expt #"+bfchannelbefore);
	run("32-bit"); //Convert to 32-bit image for PHANTAST
	run("Image Sequence... ", "dir="+bf_dir+" format=TIFF name=BF"); //Save the bf channel to its own directory


    // Reinterleave fluorescent channels - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	run("Interleave", "stack_1=[expt #"+flochannelbefore+"] stack_2=[expt #"+flochannelafter+"]"); //Combine the before and after condition channels into 1 stack
	selectImage("Combined Stacks"); 
	close("\\Others");
	run("Collect Garbage");


    // Run BaSiC correction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	if(number_of_images > 200){ //If number of images is large, run BaSiC only on subset, if it is short, just run on entire length of images
        run("Slice Keeper", "first=1 last="+number_of_images+" increment=10");
        selectImage("Combined Stacks kept stack");
        run("BaSiC ", "processing_stack=[Combined Stacks kept stack] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=4 lambda_dark=0.50");
        selectImage("Flat-field:Combined Stacks kept stack");
        run("BaSiC ", "processing_stack=[Combined Stacks] flat-field=[Flat-field:Combined Stacks kept stack] dark-field=None shading_estimation=[Skip estimation and use predefined shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=0.50 lambda_dark=0.50"); //Compute shading profile for entire stack
	}else{
        run("BaSiC ", "processing_stack=[Combined Stacks] flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Manual temporal_drift=[Replace with zero] correction_options=[Compute shading and correct images] lambda_flat=5 lambda_dark=0.50");  //Run BaSic correction on fluoresence intensity data
	}	
    selectImage("Corrected:Combined Stacks");
    close("\\Others"); //Close all unimportant windows
	selectImage("Corrected:Combined Stacks");
	rename("Corrected_Flo_Image");
	run("Add...", "value=1 stack"); //Add 1 to all pixel values as bg has been set to 0 and want to avoid multiplying by 0 later
	save(basic_dir + File.separator + "Corrected_Flo_Image.tiff"); //Save BaSic image to folder
	close("*");
	run("Collect Garbage");



    // Segment - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    if (model_id == "PHANTAST"){
        phantast_loop = getFileList(bf_dir); //List of all BF images to loop through, run PHANTAST on, and save to PHANTAST folder
        for (j = 0; j < lengthOf(phantast_loop); j++) {
            open(bf_dir+File.separator+phantast_loop[j]); //Open the jth file in the brightfield folder
            rename("Active"+(j)+""); //rename to a convention ActiveBF001 etc.
            run("PHANTAST", "sigma="+sigmaint+" epsilon="+epsiint+" do new"); //Run PHANTAST on open image with sigma and epsilon
            selectImage("PHANTAST - Active"+(j)+""); 
            save(segmentation_dir + File.separator + "PHANTAST - Active"+(j)+".tiff"); //Save image to new Phantast_Output folder
            close("*");
        } 
        close("*"); //Justs in case something straggles behind
    }

	if (substring(model_id, 0, 10) == "finetuned_") {
		// Options are finetuned_vit_l, finetuned_vit_b, and finetuned_vit_b_lm
        print("You've chosen a finetuned model.");

		run("Jones Lab Segmentation",  "model_id="+model_id+ " bf_dir="+bf_dir+ " segmentation_dir="+segmentation_dir);

		print("Finished running Jones Lab Segmentation.");
        close("*"); //Just in case something straggles behind
    }


    else {
        print("Model must be one of the options.")
    }


    // Duplicate segmented images - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	File.openSequence(segmentation_dir); //Import image sequence containing segmentations
	rename("Segmentations"); //rename to common name
	run("Duplicate...", "title=Segmentations_1 duplicate"); //Duplicate the PHANTAST output
	print("Segmentations duplicated");
	run("Interleave", "stack_1=Segmentations stack_2=Segmentations_1"); //Re-interleave with itself to double up the stack so it matches length of the fluorescence stack
	selectImage("Combined Stacks"); //Select image
	rename("Segmentations_Combined_Stack"); //Re-name for clarity
	selectImage("Segmentations_Combined_Stack");


    // Normalise segmented stack to create mask stack - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	// Scale to 0-255 if using finetuned model, invert (still 0-255) if using PHANTAST
	if (substring(model_id, 0, 10) == "finetuned_") {
		run("Multiply...", "value=255 stack");
	}
	if (model_id == "PHANTAST"){
 		run("Invert", "stack"); //Invert PHANTAST stack so cell containing regions are 255 (in 32 bit) and background is 0
	}

	
	run("Divide...", "value=255 stack"); //Divide by 255 so cell containing regions are 1 and background is 0. Now is a true mask of cell regions


    // Multiply fluorescent stack with segmented stack, threshold, and calculate results - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	open(basic_dir + File.separator + "Corrected_Flo_Image.tiff"); //Open background corrected fluoresence data
	imageCalculator("Multiply create stack", "Corrected_Flo_Image.tiff","Segmentations_Combined_Stack"); //Multiply Fluoresence stack by mask so only fluoresence from cell containing regions is included
	print("Fluorescence stack multiplied by mask");
	selectImage("Result of Corrected_Flo_Image.tiff"); //Select output of multiplication
	run("Enhance Contrast", "saturated=0.35"); // just for maximising bright regions
	setAutoThreshold("Default dark"); //Visualisation?
	setThreshold(1, 65535, "raw"); 
	run("Set Measurements...", "area mean limit display redirect=None decimal=2"); //Set measurements to save from final iamge stack
	run("Measure Stack..."); //obtain results
	selectWindow("Results");
	saveAs("Results.csv",  results_dir + File.separator + "Results.csv"); //Save results as .csv file
}