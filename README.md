# Overview
This is a ImageJ2 plugin called "Jones Lab Segmentation". The purpose of the plugin is to perform whole cell segmentation on phase contrast microscopy images. This plugin implements finetuned SAM and micro_sam models as FIJI/ImageJ plugins. These models were trained specifically for HEK293 cells from the Jones lab. Credit to the original models goes as follows:

SAM: A. Kirillov et al., "Segment Anything," 2023 IEEE/CVF International Conference on Computer Vision (ICCV), Paris, France, 2023, pp. 3992-4003, doi: 10.1109/ICCV51070.2023.00371. 

SAM code in Github, licensed under Apache 2.0: https://github.com/facebookresearch/segment-anything

micro_sam code in Github, licensed under MIT: Segment Anything for Microscopy Anwai Archit, Sushmita Nair, Nabeel Khalid, Paul Hilt, Vikas Rajashekar, Marei Freitag, Sagnik Gupta, Andreas Dengel, Sheraz Ahmed, Constantin Pape bioRxiv 2023.08.21.554208; doi: https://doi.org/10.1101/2023.08.21.554208

micro_sam github: https://github.com/computational-cell-analytics/micro-sam

This plugin was developed based on this template: https://github.com/imagej/example-imagej2-command

The macro was modified from the macro developed by Olivier at the Jones Lab here: https://github.com/engpol/JonesLabFIJIScripts/blob/main/Receptor_Expression_Macro_MESNA_MAC.

The following finetuned SAM/micro_sam models are available in **v1** of the plugin: vit_b, vit_b_lm, vit_l. We recommend choosing vit_l for high segmentation accuracy but slower speed, and vit_b for lower accuracy but faster speed.

Unless otherwise specified, all downloadable components can be found at the following **Google drive link:** https://drive.google.com/drive/folders/1uvY-v1HL_elnM82J4yAdAga7uDKibkwB?usp=share_link

# Plugin Setup
### Setup from tar gzip - recommended, but intended for MAC ONLY currently

1. Download FIJI
   1. Via https://imagej.net/software/fiji/
   2. Install at /Applications

2. Download BaSiC and PHANTAST plugins
   1. Launch FIJI
   2. Go to Help > Update > (wait for updates to run) > Manage Update Sites > Select plugins and apply updates
   3. Close FIJI

3. Download macro
   1. Via Github (current repository)
      1. If you prefer to download just the file rather than the entire git repository, we suggest copying the raw file directly from the repository.
   2. Save as macro in FIJI under the Plugins menu

4. Download supporting folder (plugin_dir)
   1. Via Github (current repository)
       1. If you prefer to download just the folder rather than the entire git repository, we suggest creating a new directory called plugin_dir at the location specified belowand copying the contents of the raw file directly from the repository into the new directory.
   2. Install at  /Applications/Fiji.app (full filepath will be /Applications/Fiji.app/plugin_dir)

5. Download plugin
   1. Via Google drive (jar file)
   2. Install at /Applications/Fiji.app/plugins (directory should already exist from FIJI installation)
   3. To confirm it is installed, launch FIJI and look for "Jones Lab Segmentation" under the Plugins menu

6. Download model(s)
   1. Via Google Drive (pt file(s))
   2. Install at /Applications/Fiji.app/plugin_dir
   3. If you choose to save the models at a different location:
      1. Open microsam_plugin.py (/Applications/Fiji.app/plugin_dir/microsam_plugin.py)
      2. Modify model section to point to correct model filepaths
   4. Note: It is possible to finetune your own version of SAM or micro_sam. If you choose to do this, you will need to modify the plugin to point to your new model filepaths.

7. Download bundled python environment (tar.gz)
   1. Via Google Drive (tar.gz file)
      1. Note: Safari may auto unzip file, downloading it into a .tar file. See https://apple.stackexchange.com/questions/260152/why-does-tar-gz-automatically-extract-the-gzip-archive-when-i-download-it-in-sa
   2. Create directory in Fiji.app folder and unpack
      1. cd /Applications/Fiji.app
      2. mkdir -p test_tar_env
      3. Once file has downloaded:
         1. Navigate to home directory via cd ~ (or wherever your tar file is)
         2. If file is compressed (.tar.gz): tar -xzf test-env.tar.gz -C /Applications/Fiji.app/test_tar_env
         3. If file is decompressed (.tar): tar -xvf test-env.tar -C /Applications/Fiji.app/test_tar_env
      4. Run command: /Applications/Fiji.app/test_tar_env/bin/conda-unpack
         1. Note: May need to modify conda-unpack script to point to new python
            1. nano /Applications/Fiji.app/test_tar_env/bin/conda-unpack
            2. Change first line from #!/usr/bin/env python to #!/Applications/Fiji.app/test_tar_env/bin/python
            3. Now run full conda-unpack command again
   3. Activate the environment to confirm the unpack was successful: source /Applications/Fiji.app/test_tar_env/bin/activate

### Setup from yaml - not recommended due to dependency challenges

1. Download FIJI and macro as specified above.
2. Clone the repo.
3. Build a conda environment from the appropriate yaml file.
4. Install any other necessary dependencies (tifffile, natsort, etc) to the virtual environment.
5. Install micro-sam to the virtual environment. It is recommended by the authors to use mamba. Micromamba in the base environment (alongside conda) is usually appropriate, if your system does not have an existing mamba installation. Instructions on installing micro-sam here: https://computational-cell-analytics.github.io/micro-sam/micro_sam.html#installation
6. Place the JAR file in the plugins directory for the FIJI application.
7. Place the Python directory (script and helper file) and model checkpoints in the desired location. The application's base directory (e.g. 'Fiji.app') is usually appropriate.
8. Ensure all filepaths in the Python and Java scripts are correct for your workflow.
9. If anything was changed in the Java project, run a clean install (mvn clean install -X). Once complete, copy the JAR file to the FIJI plugins directory.
10. Set the environment variable to your Python installation. This works best if it is the Python installed in the virtual environment.
11. Launch FIJI from the terminal by navigating to the directory and running the executable.
12. Find the plugin in the Plugins menu, and go!

# Data Setup
### Using plugin alone

1. Full TIF images should be an interleaved set of 4 TIF images – 1 fluorescent before drug application, 1 brightfield before, 1 fluorescent after, 1 brightfield after.
2. Brightfield_Stack should contain (deinterleaved) brightfield TIF images to be segmented. If deinterleaving from a full TIF image as described above, Brightfield_Stack should contain the 2nd out of 4 images per full TIF.
3. Save data according to this pattern:
   1. Experiments folder
      1. Experiment 1 folder
         1. Brightfield_Stack folder
            1. Brightfield TIF image 1
            2. Brightfield TIF image 2
            3. etc
         2. (Optional) Full TIF image 1
         3. (Optional) Full TIF image 2
         4. etc
      2. Experiment 2 folder
         1. Brightfield_Stack folder
            1. Brightfield TIF image 1
            2. Brightfield TIF image 2
            3. etc
         2. (Optional) Full TIF image 1
         3. (Optional) Full TIF image 2
         4. etc
      3. etc

### Using plugin as part of macro

1. Full TIF images should be an interleaved set of 4 TIF images – 1 fluorescent before drug application, 1 brightfield before, 1 fluorescent after, 1 brightfield after.
2. Save data according to this pattern:
   1. Experiments folder
      1. Experiment 1 folder
         1. Full TIF image 1
         2. Full TIF image 2
         3. etc
      2. Experiment 2 folder
         1. Full TIF image 1
         2. Full TIF image 2
         3. etc
      3. etc

# Plugin Use

1. Open FIJI
2. Open Window > Console
3. Either run plugin alone via Plugins > Jones Lab Segmentation OR run macro via Plugins > (select macro)
   1. Ensure correct model name and data filepaths are specified. Model choices are **finetuned_vit_b**, **finetuned_vit_b_lm**,  **finetuned_vit_l**, and **PHANTAST** (dependent on which model(s) and/or PHANTAST you have downloaded).
4. Run! Progress will be shown in the console and any necessary new folders/data will be created automatically. This could take several minutes per batch (3 images at a time).

