<h1> Overview </h1>
This is a ImageJ2 plugin called "Jones Lab Segmentation". The purpose of the plugin is to perform whole cell segmentation on phase contrast microscopy images; specifically, HEK293 cells from the Jones lab. This plugin implements finetuned SAM and micro_sam models as FIJI/ImageJ plugins. Credit to the original is as follows:

SAM: A. Kirillov et al., "Segment Anything," 2023 IEEE/CVF International Conference on Computer Vision (ICCV), Paris, France, 2023, pp. 3992-4003, doi: 10.1109/ICCV51070.2023.00371. 

SAM code in Github, licensed under Apache 2.0: https://github.com/facebookresearch/segment-anything

micro_sam code in Github, licensed under MIT: Segment Anything for Microscopy Anwai Archit, Sushmita Nair, Nabeel Khalid, Paul Hilt, Vikas Rajashekar, Marei Freitag, Sagnik Gupta, Andreas Dengel, Sheraz Ahmed, Constantin Pape bioRxiv 2023.08.21.554208; doi: https://doi.org/10.1101/2023.08.21.554208

micro_sam github: https://github.com/computational-cell-analytics/micro-sam
\
\
The following models are available in **v1** of the plugin: vit_b, vit_b_lm, vit_l
We recommend choosing vit_l for high segmentation accuracy but slower speed, and vit_b for lower accuracy but faster speed
\
\
Unless otherwise specified, all downloadable components can be found at the following **Google drive link:** https://drive.google.com/drive/folders/1uvY-v1HL_elnM82J4yAdAga7uDKibkwB?usp=share_link

<h1> Plugin Setup </h1>
<h3> Setup from tar gzip - recommended, but intended for MAC ONLY currently </h3>
<ol>

  <li> Download FIJI
    <ol>
      <li>Via https://imagej.net/software/fiji/</li>
      <li>Install at /Applications</li>
    </ol>
  </li>
  
  <li> Download BaSiC and PHANTAST plugins
    <ol>
      <li>Launch FIJI</li>
      <li>Go to Help > Update > (wait for updates to run) > Manage Update Sites > Select plugins and apply updates</li>
      <li>Close FIJI</li>
    </ol>
  </li>
  
  <li> Download macro
    <ol>
      <li>Via Github: *insert link* </li>
      <li>Save as macro in FIJI under the Plugins menu</li>
    </ol>
  </li>

  <li> Download supporting folder (plugin_dir)
    <ol>
      <li>Via Github: https://github.com/nicoleaudia/msc_prj_jones_workflow/tree/clean-branch </li>
      <li>Install at  /Applications/Fiji.app (full filepath will be /Applications/Fiji.app/plugin_dir)</li>
    </ol>
  </li>

  <li>Download plugin
    <ol>
      <li>Via Google drive (jar file) </li>
      <li>Install at /Applications/Fiji.app/plugins </li>
      <li>To confirm it is installed, launch FIJI and look for “Jones Lab Segmentation” </li>
    </ol>
  </li>

  <li>Download model(s)
    <ol>
      <li> Via Google Drive </li>
      <li> Install at /Applications/Fiji.app/plugin_dir </li>
      <li> If you choose to save the models at a different location: 
        <ol>
          <li> Open microsam_plugin.py (/Applications/Fiji.app/plugin_dir/microsam_plugin.py) </li>
          <li> Modify model section to point to correct model filepaths </li>
        </ol>
      </li>
    </ol>

  <li>Download bundled python environment (tar.gz)
    <ol>
      <li> Via Google Drive (tar.gz file) 
        <ol>
          <li> Note: Safari may auto unzip file, downloading it into a .tar file. See https://apple.stackexchange.com/questions/260152/why-does-tar-gz-automatically-extract-the-gzip-archive-when-i-download-it-in-sa </li>
        </ol>
      </li>
      <li> Create directory in Fiji.app folder and unpack 
        <ol>
          <li>cd /Applications/Fiji.app</li>
          <li>mkdir -p test_tar_env</li>
          <li>Once file has downloaded: 
            <ol>
              <li> Navigate to home directory via cd ~ (or wherever your tar file is) </li>
              <li>If file is compressed (.tar.gz): tar -xzf test-env.tar.gz -C /Applications/Fiji.app/test_tar_env </li>
              <li>If file is decompressed (.tar): tar -xvf test-env.tar -C /Applications/Fiji.app/test_tar_env </li>
            </ol>
          </li>
          <li>Run command: /Applications/Fiji.app/test_tar_env/bin/conda-unpack
            <ol>
              <li>Note: May need to modify conda-unpack script to point to new python
                <ol>
                  <li> nano /Applications/Fiji.app/test_tar_env/bin/conda-unpack </li>
                  <li> Change first line from #!/usr/bin/env python to #!/Applications/Fiji.app/test_tar_env/bin/python </li>
                  <li> Now run full conda-unpack command again </li>
                </ol>
              </li>
            </ol>
          </li>
        </ol>
      </li>
      <li>Activate the environment to confirm the unpack was successful: source /Applications/Fiji.app/test_tar_env/bin/activate</li>
    </ol>
  </li>
  </li>
</ol>

<h3> Setup from yaml - not recommended due to dependency challenges </h3>
<ol>
  <li> Clone the repo. </li>
  <li> Build a conda environment from the appropriate yaml file. </li>
  <li> Install any other necessary dependencies (tifffile, natsort, etc) to the virtual environment. </li>
  <li> Install micro-sam to the virtual environment. It is recommended by the authors to use mamba. Micromamba in the base environment (alongside conda) is usually appropriate, if your system does not have an existing mamba installation. Instructions on installing micro-sam here: https://computational-cell-analytics.github.io/micro-sam/micro_sam.html#installation </li>
  <li> Place the JAR file in the plugins directory for the FIJI application. </li>
  <li> Place the Python directory (script and helper file) and model checkpoints in the desired location. The application's base directory (e.g. 'Fiji.app') is usually appropriate. </li>
  <li> Ensure all filepaths in the Python and Java scripts are correct for your workflow. </li>
  <li> If anything was changed in the Java project, run a clean install (mvn clean install -X). Once complete, copy the JAR file to the FIJI plugins directory. </li> 
  <li> Set the environment variable to your Python installation. This works best if it is the Python installed in the virtual environment. </li>
  <li> Launch FIJI from the terminal by navigating to the directory and running the executable. </li>
  <li> Find the plugin in the Plugins menu, and go! </li>
</ol>

<h1> Data Setup </h1>
<h3> Using plugin alone </h3>
<ol>
  <li> Full TIF images should be an interleaved set of 4 TIF images – 1 fluorescent before drug application, 1 brightfield before, 1 fluorescent after, 1 brightfield after. </li>
  <li> Brightfield_Stack should contain (deinterleaved) brightfield TIF images to be segmented. If deinterleaving from a full TIF image as described above, Brightfield_Stack should contain the 2nd out of 4 images per full TIF. </li>
  <li>Save data according to this pattern:
    <ol>
      <li> Experiments folder 
        <ol>
          <li> Experiment 1 folder 
            <ol>
              <li> Brightfield_Stack folder
                <ol>
                  <li> Brightfield TIF image 1 </li>
                  <li> Brightfield TIF image 2 </li>
                  <li> etc </li>
                </ol>
              </li>
              <li> (Optional) Full TIF image 1 </li>
              <li> (Optional) Full TIF image 2 </li>
              <li> etc </li>
            </ol>
          </li>
          <li> Experiment 2 folder 
            <ol>
              <li> Brightfield_Stack folder
                <ol>
                  <li> Brightfield TIF image 1 </li>
                  <li> Brightfield TIF image 2 </li>
                  <li> etc </li>
                </ol>
              </li>
              <li> (Optional) Full TIF image 1 </li>
              <li> (Optional) Full TIF image 2 </li>
              <li> etc </li>
            </ol>
          </li> 
          <li> etc </li>
        </ol>
      </li>
    </ol>
  </li>
</ol>

<h3> Using plugin as part of macro </h3>
<ol>
  <li> Full TIF images should be an interleaved set of 4 TIF images – 1 fluorescent before drug application, 1 brightfield before, 1 fluorescent after, 1 brightfield after. </li>
  <li> Save data according to this pattern: 
    <ol> 
      <li> Experiments folder
        <ol>
          <li> Experiment 1 folder 
            <ol>
              <li> Full TIF image 1 </li>
              <li> Full TIF image 2 </li>
              <li> etc </li>
            </ol>
          </li>
          <li> Experiment 2 folder 
            <ol>
              <li> Full TIF image 1 </li>
              <li> Full TIF image 2 </li>
              <li> etc </li>
            </ol>
          </li>
          <li> etc </li>
        </ol>
      </li>
    </ol>
  </li>
</ol>

<h1> Plugin Use </h1>
<ol>
  <li> Open FIJI </li>
  <li> Open Window > Console </li>
  <li> Either run plugin alone via Plugins > Jones Lab Segmentation OR run macro via Plugins > (select macro) 
    <ol>
      <li> Ensure correct model name and data filepaths are specified </li>
    </ol>
  </li>
  <li> Run! Progress will be shown in the console and any necessary new folders/data will be created automatically. This could take several minutes per batch (3 images at a time). </li>
</ol>

