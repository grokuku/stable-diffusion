**Subsequent changelog history can be found in Releases**

- **Version 2.0.2** :  
  move .cache folder to stable-diffusion/temp to avoid filling unraid's docker.img file.  
  (hopefully) fix all the things I broke in the last update :)

- **Version 2.0.0** :  
  Utilize Conda to manage dependencies efficiently.  
  Prepared for Reactor in Auto1111, SD-Next, and ComfyUI.  
  More common folders merged in the models folder.  
  Split install scripts for easier maintenance.  
  Implemented various fixes.

- **Version 1.5.1** :  
  Added a fix for Automatic1111/dreambooth

- **Version 1.5.0** :  
  Added StableSwarm and VoltaML

- **Version 1.4.0** :  
  Added FaceFusion

- **Version 1.3.0** :  
  Added Kubin  (Kubin is only for testing, not production ready)
  Corrected update of ComfyUI at startup not working

- **Version 1.2.0** :  
  Added Lama-cleaner and Kohya

- **Version 1.1.0** :  
  Added Focus as interface 06  
  Small Fixes

- **Version 1.0.0** :  
  Lots of modifications on directory structure.  
  Before using this version it's best to do a backup, do a clean install and restore models,loras, ect from the backup.