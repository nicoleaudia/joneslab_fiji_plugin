// package com.imperial.joneslab;

// import java.io.BufferedReader;
// import java.io.IOException;
// import java.io.InputStreamReader;
// import java.io.File;

// public class PythonRunner {

//     public void runPythonScript(String bf_dir, String segmentation_dir) {
//         // Step 1: Check for PYTHON_PATH environment variable
//         String pythonPath = System.getenv("PYTHON_PATH");

//         // Step 2: If PYTHON_PATH is not set, default to 'python' in the system path
//         if (pythonPath == null || pythonPath.isEmpty()) {
//             pythonPath = "python";  // Use system default python
//         }

//         try {
//             // Dynamically locate plugin_dir and microsam_plugin.py
//             File currentDir = new File(System.getProperty("user.dir"));  // Get FIJI's current working directory
//             File fijiInstallDir = currentDir.getParentFile().getParentFile();  // Navigate to /Applications/Fiji.app
//             File pluginDir = new File(fijiInstallDir, "plugin_dir");  // Locate plugin_dir

//             // Check if plugin_dir exists
//             if (pluginDir.exists() && pluginDir.isDirectory()) {
//                 File pythonScript = new File(pluginDir, "microsam_plugin.py");  // Locate the Python script

//                 if (pythonScript.exists()) {
//                     // Step 3: Use the pythonPath to run the Python script, passing bf_dir and segmentation_dir as an arguments
//                     ProcessBuilder processBuilder = new ProcessBuilder(
//                         pythonPath, pythonScript.getAbsolutePath(), bf_dir, segmentation_dir
//                     );
//                     processBuilder.redirectErrorStream(true);
//                     Process process = processBuilder.start();

//                     // Step 4: Handle output from the Python process
//                     BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
//                     String line;
//                     while ((line = reader.readLine()) != null) {
//                         System.out.println(line);  // Print each line to the console
//                     }

//                     int exitCode = process.waitFor();
//                     System.out.println("Python script exited with code: " + exitCode);
//                 } else {
//                     System.err.println("Python script not found in plugin_dir.");
//                 }
//             } else {
//                 System.err.println("plugin_dir not found.");
//             }

//         } catch (IOException | InterruptedException e) {
//             e.printStackTrace();
//         }
//     }
// }


// CHANGING 10/7:

package com.imperial.joneslab;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.File;

public class PythonRunner {

    public static void runPythonScript(String pythonInterpreter, File pythonScript, String modelId, String bfDir, String segmentationDir) throws IOException, InterruptedException {
        // Execute Python script with necessary arguments
        ProcessBuilder processBuilder = new ProcessBuilder(pythonInterpreter, pythonScript.getAbsolutePath(), modelId, bfDir, segmentationDir);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        // Print Python outputs to console
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }

        // Check if Python script executed successfully
        int exitCode = process.waitFor();
        if (exitCode != 0) {
            System.err.println("Python script exited with error code: " + exitCode);
        }
    }
}
