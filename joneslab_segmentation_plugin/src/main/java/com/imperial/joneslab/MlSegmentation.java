

// Last modification: 10/31/24; Last significant modification: 10/7/24

package com.imperial.joneslab;

import java.awt.GraphicsEnvironment;
import org.scijava.command.Command;
import org.scijava.plugin.Parameter;
import org.scijava.plugin.Plugin;
import org.scijava.ui.UIService;
import net.imagej.ImageJ;
import net.imglib2.type.numeric.RealType;
import py4j.GatewayServer;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;
import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.util.Date;

@Plugin(type = Command.class, menuPath = "Plugins>Jones Lab Segmentation")
public class MlSegmentation<T extends RealType<T>> implements Command {

    @Parameter
    private UIService uiService;

    @Parameter(label = "Model ID")
    private String model_id;

    @Parameter(label = "Brightfield Directory")
    private String bf_dir;

    @Parameter(label = "Segmentation Directory")
    private String segmentation_dir;

    @Override
    public void run() {
        try {
            if (GraphicsEnvironment.isHeadless()) {
                runHeadless();
            } else {
                System.out.println("Running plugin with GUI");
                runWithUI();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void main(final String... args) throws Exception {
        new MlSegmentation<>().run();
    }

    public void runHeadless() throws Exception {
        System.out.println("Running in headless mode!");

        // Assuming a default Python interpreter path for headless mode
        String pythonInterpreter = "/Applications/Fiji.app/python_env/bin/python";
        File pythonScript = new File("microsam_plugin.py");  // Path to your script, should be adjusted accordingly

        PythonRunner.runPythonScript(pythonInterpreter, pythonScript, model_id, bf_dir, segmentation_dir);
    }

    public void runWithUI() throws Exception {
        ImageJ ij = ImageJSingleton.getInstance();
        GatewayServer server = new GatewayServer(new PythonGateway(), 0);

        try {
            server.start();
            System.out.println("Gateway server started");

            // Dynamically locate plugin_dir and microsam_plugin.py
            File currentDir = new File(System.getProperty("user.dir"));
            File pluginDir = findPluginDir(currentDir, 3);

            if (pluginDir == null || !pluginDir.exists() || !pluginDir.isDirectory()) {
                System.err.println("plugin_dir not found.");
                return;
            }

            File pythonScript = new File(pluginDir, "microsam_plugin.py");
            if (!pythonScript.exists()) {
                System.err.println("Python script not found in plugin_dir.");
                return;
            }

            // Step 1: Attempt to load Python path from the .ini config file
            String pythonInterpreter = null;
            // File configFile = new File(pluginDir, "joneslab_pythonenv_config.ini");
            File configFile = new File(pluginDir, "testing.ini"); // NOTE: change to correct ini if using
            if (configFile.exists()) {
                System.out.println("Attempting to load configuration from: " + configFile.getAbsolutePath());
                Properties props = new Properties();
                try (FileInputStream in = new FileInputStream(configFile)) {
                    props.load(in);
                    pythonInterpreter = props.getProperty("python_path", "").trim();
                    if (!pythonInterpreter.isEmpty()) {
                        System.out.println("Loaded python path from config file: '" + pythonInterpreter + "'");
                    }
                } catch (IOException e) {
                    System.err.println("Failed to load configuration file: " + e.getMessage());
                }
            }

            // Step 2: If Python interpreter is not set from the .ini file, default to bundled Python
            if (pythonInterpreter == null || pythonInterpreter.isEmpty()) {
                pythonInterpreter = "/Applications/Fiji.app/test_tar_env/bin/python"; // NOTE: ensure this is bundle path from tar.gz unpacking
                System.out.println("Using bundled Python interpreter: " + pythonInterpreter);
            }

            // Verify that the Python interpreter exists
            File pythonExecutable = new File(pythonInterpreter);
            if (!pythonExecutable.exists()) {
                System.err.println("Python interpreter not found at: " + pythonInterpreter);
                return;
            }

            // Execute the Python script using PythonRunner utility
            PythonRunner.runPythonScript(pythonInterpreter, pythonScript, model_id, bf_dir, segmentation_dir);

        } catch (Exception e) {
            System.err.println("Exception occurred during runWithUI execution: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (server != null) {
                server.shutdown();
                System.out.println("Gateway server stopped.");
            }
            if (ij != null && ij.context() != null) {
                ij.context().dispose();
            }
            if (ij != null && ij.ui() != null) {
                ij.ui().dispose();
            }
        }

        System.out.println("Exiting runWithUI() method");
    }

    public static File findPluginDir(File startDir, int maxDepth) {
        if (maxDepth == 0 || startDir == null) {
            System.out.println("Reached maximum depth or null directory");
            return null;
        }

        File[] files = startDir.listFiles();
        if (files != null) {
            System.out.println("Searching directory " + startDir.getAbsolutePath());
            for (File file : files) {
                if (file.isDirectory() && file.getName().equals("plugin_dir")) {
                    return file;
                }
            }
        }

        return findPluginDir(startDir.getParentFile(), maxDepth - 1);
    }

    public static class PythonGateway {
        public void invokePythonFunction() {
            System.out.println("This text is being printed from invokePythonFunction()");
        }
    }

    private static void monitorThreadCount(Process process) {
        new Thread(() -> {
            boolean processKilled = false;
            try (PrintWriter logWriter = new PrintWriter(new FileWriter("process_kill_log.txt", true))) {
                while (true) {
                    int threadCount = getThreadCount();
                    System.out.println("Current thread count: " + threadCount);
                    if (threadCount > 100 && !processKilled) {
                        String errorMessage = "Thread count exceeded 100 at " + new Date() + ". Killing the process.";
                        System.err.println(errorMessage);
                        logWriter.println(errorMessage);
                        process.destroy();
                        logWriter.println("Process killed at " + new Date());
                        processKilled = true;
                        break;
                    }
                    Thread.sleep(1000);
                }
            } catch (InterruptedException | IOException e) {
                e.printStackTrace();
            }
        }).start();
    }

    private static int getThreadCount() {
        ThreadMXBean threadMXBean = ManagementFactory.getThreadMXBean();
        return threadMXBean.getThreadCount();
    }
}

// Singleton Class for ImageJ instance
class ImageJSingleton {
    private static ImageJ instance;

    private ImageJSingleton() {}

    public static synchronized ImageJ getInstance() {
        if (instance == null) {
            instance = new ImageJ();
            System.out.println("Created new ImageJ instance");
        } else {
            System.out.println("Using existing ImageJ instance");
        }
        return instance;
    }
}
