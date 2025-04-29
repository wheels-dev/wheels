/**
 * Scaffold and integrate modern frontend frameworks with Wheels
 * 
 * {code:bash}
 * wheels generate frontend --framework=react
 * wheels generate frontend --framework=vue
 * wheels generate frontend --framework=alpine
 * {code}
 */
component extends="../base" {

    /**
     * @framework Frontend framework to use (react, vue, alpine)
     * @path Directory to install frontend (defaults to /app/assets/frontend)
     * @api Generate API endpoint for frontend
     */
    function run(
        required string framework,
        string path="app/assets/frontend",
        boolean api=false
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Frontend Generator");
        print.line();
        
        // Validate framework selection
        local.supportedFrameworks = ["react", "vue", "alpine"];
        if (!arrayContains(local.supportedFrameworks, lCase(arguments.framework))) {
            error("Unsupported framework: #arguments.framework#. Please choose from: #arrayToList(local.supportedFrameworks)#");
        }
        
        // Create directory if it doesn't exist
        local.fullPath = fileSystemUtil.resolvePath(arguments.path);
        if (!directoryExists(local.fullPath)) {
            directoryCreate(local.fullPath);
        }
        
        // Create package.json
        local.packageJson = createPackageJson(arguments.framework);
        file action='write' file='#local.fullPath#/package.json' mode='777' output='#local.packageJson#';
        
        // Create base configuration files
        switch (lCase(arguments.framework)) {
            case "react":
                setupReactProject(local.fullPath);
                break;
            case "vue":
                setupVueProject(local.fullPath);
                break;
            case "alpine":
                setupAlpineProject(local.fullPath);
                break;
        }
        
        // Create asset pipeline integration
        setupAssetPipeline(arguments.framework, local.fullPath);
        
        // Generate API if requested
        if (arguments.api) {
            command("wheels generate api-resource")
                .params(name="api", docs=true)
                .run();
        }
        
        // Final instructions
        print.line();
        print.greenLine("Frontend scaffolding for #arguments.framework# has been set up in #arguments.path#");
        print.yellowLine("Next steps:");
        print.line("1. Navigate to #arguments.path#");
        print.line("2. Run 'npm install' to install dependencies");
        print.line("3. Run 'npm run dev' for development or 'npm run build' for production");
        print.line();
    }
    
    /**
     * Generate package.json content based on selected framework
     */
    private string function createPackageJson(required string framework) {
        local.packageJson = {
            "name": "cfwheels-frontend",
            "version": "1.0.0",
            "description": "Frontend for Wheels application",
            "scripts": {
                "dev": "vite",
                "build": "vite build",
                "preview": "vite preview"
            },
            "dependencies": {},
            "devDependencies": {
                "vite": "^4.0.0"
            }
        };
        
        // Add framework-specific dependencies
        switch (lCase(arguments.framework)) {
            case "react":
                local.packageJson.dependencies["react"] = "^18.2.0";
                local.packageJson.dependencies["react-dom"] = "^18.2.0";
                local.packageJson.devDependencies["@vitejs/plugin-react"] = "^3.0.0";
                break;
            case "vue":
                local.packageJson.dependencies["vue"] = "^3.2.45";
                local.packageJson.devDependencies["@vitejs/plugin-vue"] = "^4.0.0";
                break;
            case "alpine":
                local.packageJson.dependencies["alpinejs"] = "^3.10.5";
                break;
        }
        
        return serializeJSON(local.packageJson, "struct");
    }
    
    /**
     * Setup React project structure
     */
    private void function setupReactProject(required string path) {
        // Create src directory
        if (!directoryExists(arguments.path & "/src")) {
            directoryCreate(arguments.path & "/src");
        }
        
        // Create main.jsx
        local.mainContent = 'import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);';
        file action='write' file='#arguments.path#/src/main.jsx' mode='777' output='#local.mainContent#';
        
        // Create App.jsx
        local.appContent = 'import { useState } from "react";
import "./App.css";

function App() {
  const [count, setCount] = useState(0);
  
  return (
    <div className="App">
      <header className="App-header">
        <h1>Wheels + React</h1>
        <p>
          <button onClick={() => setCount((count) => count + 1)}>
            count is {count}
          </button>
        </p>
      </header>
    </div>
  );
}

export default App;';
        file action='write' file='#arguments.path#/src/App.jsx' mode='777' output='#local.appContent#';
        
        // Create index.css
        local.cssContent = ':root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

h1 {
  font-size: 3.2em;
  line-height: 1.1;
}

button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  background-color: ##1a1a1a;
  color: white;
  cursor: pointer;
  transition: border-color 0.25s;
}';
        file action='write' file='#arguments.path#/src/index.css' mode='777' output='#local.cssContent#';
        
        // Create vite.config.js
        local.viteContent = 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../../../public/assets/frontend",
    emptyOutDir: true,
    manifest: true,
  },
});';
        file action='write' file='#arguments.path#/vite.config.js' mode='777' output='#local.viteContent#';
        
        print.greenLine("React project structure created");
    }
    
    /**
     * Setup Vue project structure
     */
    private void function setupVueProject(required string path) {
        // Create src directory
        if (!directoryExists(arguments.path & "/src")) {
            directoryCreate(arguments.path & "/src");
        }
        
        // Create main.js
        local.mainContent = 'import { createApp } from "vue";
import App from "./App.vue";
import "./style.css";

createApp(App).mount("##app");';
        file action='write' file='#arguments.path#/src/main.js' mode='777' output='#local.mainContent#';
        
        // Create App.vue
        local.appContent = '<script setup>
import { ref } from "vue";

const count = ref(0);
</script>

<template>
  <div class="app">
    <header class="app-header">
      <h1>Wheels + Vue</h1>
      <p>
        <button type="button" @click="count++">count is {{ count }}</button>
      </p>
    </header>
  </div>
</template>

<style scoped>
.app {
  text-align: center;
  margin-top: 2rem;
}
</style>';
        file action='write' file='#arguments.path#/src/App.vue' mode='777' output='#local.appContent#';
        
        // Create style.css
        local.cssContent = ':root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

h1 {
  font-size: 3.2em;
  line-height: 1.1;
}

button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  background-color: ##1a1a1a;
  color: white;
  cursor: pointer;
  transition: border-color 0.25s;
}';
        file action='write' file='#arguments.path#/src/style.css' mode='777' output='#local.cssContent#';
        
        // Create vite.config.js
        local.viteContent = 'import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  plugins: [vue()],
  build: {
    outDir: "../../../public/assets/frontend",
    emptyOutDir: true,
    manifest: true,
  },
});';
        file action='write' file='#arguments.path#/vite.config.js' mode='777' output='#local.viteContent#';
        
        print.greenLine("Vue project structure created");
    }
    
    /**
     * Setup Alpine.js project structure
     */
    private void function setupAlpineProject(required string path) {
        // Create src directory
        if (!directoryExists(arguments.path & "/src")) {
            directoryCreate(arguments.path & "/src");
        }
        
        // Create main.js
        local.mainContent = 'import Alpine from "alpinejs";
import "./style.css";

window.Alpine = Alpine;
Alpine.start();';
        file action='write' file='#arguments.path#/src/main.js' mode='777' output='#local.mainContent#';
        
        // Create index.html for Alpine
        local.htmlContent = '<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Wheels + Alpine.js</title>
  </head>
  <body>
    <div id="app" x-data="{ count: 0 }">
      <header class="app-header">
        <h1>Wheels + Alpine.js</h1>
        <p>
          <button type="button" x-on:click="count++">
            count is <span x-text="count"></span>
          </button>
        </p>
      </header>
    </div>
    <script type="module" src="./src/main.js"></script>
  </body>
</html>';
        file action='write' file='#arguments.path#/index.html' mode='777' output='#local.htmlContent#';
        
        // Create style.css
        local.cssContent = ':root {
  font-family: Inter, system-ui, Avenir, Helvetica, Arial, sans-serif;
  line-height: 1.5;
  font-weight: 400;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

h1 {
  font-size: 3.2em;
  line-height: 1.1;
}

button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  background-color: ##1a1a1a;
  color: white;
  cursor: pointer;
  transition: border-color 0.25s;
}';
        file action='write' file='#arguments.path#/src/style.css' mode='777' output='#local.cssContent#';
        
        // Create vite.config.js
        local.viteContent = 'import { defineConfig } from "vite";

export default defineConfig({
  build: {
    outDir: "../../../public/assets/frontend",
    emptyOutDir: true,
    manifest: true,
  },
});';
        file action='write' file='#arguments.path#/vite.config.js' mode='777' output='#local.viteContent#';
        
        print.greenLine("Alpine.js project structure created");
    }
    
    /**
     * Setup asset pipeline integration
     */
    private void function setupAssetPipeline(required string framework, required string path) {
        // Create helper for frontend assets
        local.assetsHelperPath = fileSystemUtil.resolvePath("app/helpers/frontend_assets.cfm");
        
        // Using CFML string literals to simplify quotes management
        local.assetsHelperContent = '<cfscript>
/**
 * Includes frontend assets in the view
 * Usage: #frontendAssets()#
 */
function frontendAssets() {
    local.manifestPath = expandPath("/public/assets/frontend/manifest.json");
    local.scriptTag = "";
    local.styleTag = "";
    
    if (fileExists(local.manifestPath)) {
        local.manifest = deserializeJSON(fileRead(local.manifestPath));
        
        // Get the main entry point
        local.mainKey = "src/main.";
        
        // Add framework-specific file extension
        switch (lCase("' & framework & '")) {
            case "react":
                local.mainKey = local.mainKey & "jsx";
                break;
            case "vue":
            case "alpine":
                local.mainKey = local.mainKey & "js";
                break;
        }
        
        if (structKeyExists(local.manifest, local.mainKey)) {
            local.entry = local.manifest[local.mainKey];
            
            // Script tag for the main JS file
            if (structKeyExists(local.entry, "file")) {
                local.scriptTag = "<script type=""module"" src=""/assets/frontend/" & local.entry.file & """></script>";
            }
            
            // CSS files
            if (structKeyExists(local.entry, "css") && isArray(local.entry.css)) {
                for (local.cssFile in local.entry.css) {
                    local.styleTag = local.styleTag & "<link rel=""stylesheet"" href=""/assets/frontend/" & local.cssFile & """>";
                }
            }
        }
    }
    
    return local.styleTag & local.scriptTag;
}
</cfscript>';
        
        file action='write' file='#local.assetsHelperPath#' mode='777' output='#local.assetsHelperContent#';
        
        // Create a sample view that uses the frontend
        local.layoutPath = fileSystemUtil.resolvePath("app/views/layouts/frontend.cfm");
        
        local.layoutContent = '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wheels with #arguments.framework#</title>
    #frontendAssets()#
</head>
<body>
    <div id="';
        
        // Add framework-specific container ID
        switch (lCase(arguments.framework)) {
            case "react":
                local.layoutContent &= 'root';
                break;
            case "vue":
                local.layoutContent &= 'app';
                break;
            case "alpine":
                local.layoutContent &= 'app" x-data="{ count: 0 ';
                break;
        }
        
        local.layoutContent &= '"></div>
    
    <div class="cfwheels-content">
        #contentForLayout()#
    </div>
</body>
</html>';
        
        file action='write' file='#local.layoutPath#' mode='777' output='#local.layoutContent#';
        
        print.greenLine("Frontend asset pipeline integration created");
    }
}