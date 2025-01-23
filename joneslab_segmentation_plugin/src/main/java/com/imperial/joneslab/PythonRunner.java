// Last significant modification: 10/7/24

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
