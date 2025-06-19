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
     * Initialize the command
     */
    function init() {
        return this;
    }

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
        print.boldMagentaLine("Wheels Frontend Framework Generator");
        print.line();

        // Validate framework
        local.supportedFrameworks = ["react", "vue", "alpine"];
        if (!arrayContains(local.supportedFrameworks, lCase(arguments.framework))) {
            error("Unsupported framework: #arguments.framework#. Please choose from: #arrayToList(local.supportedFrameworks)#");
        }

        // Ensure target directory exists
        local.targetPath = fileSystemUtil.resolvePath(arguments.path);
        if (!directoryExists(local.targetPath)) {
            directoryCreate(local.targetPath);
            print.greenLine("Created directory: #arguments.path#");
        }

        print.line("Setting up #arguments.framework# in #arguments.path#...");

        switch(lCase(arguments.framework)) {
            case "alpine":
                setupAlpine(local.targetPath);
                break;
            case "react":
                setupReact(local.targetPath);
                break;
            case "vue":
                setupVue(local.targetPath);
                break;
        }

        // Generate API endpoint if requested
        if (arguments.api) {
            print.line();
            print.line("Generating API endpoint for frontend...");
            // Create a simple API controller for the frontend
            command("wheels generate api-resource")
                .params(name="frontend-data")
                .run();
        }

        print.line();
        print.greenLine("Frontend setup complete!");
        print.line();
    }

    private function setupAlpine(required string path) {
        // Create Alpine.js setup
        local.indexContent = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wheels + Alpine.js</title>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        body { font-family: sans-serif; padding: 2rem; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Wheels + Alpine.js</h1>
        <div x-data="{ message: ''Welcome to Alpine.js!'', count: 0 }">
            <p x-text="message"></p>
            <button @click="count++" x-text="''Clicked '' + count + '' times''"></button>
        </div>
    </div>
</body>
</html>';

        file action='write' file='#arguments.path#/index.html' mode='777' output='#trim(local.indexContent)#';
        print.greenLine("Created Alpine.js template at #arguments.path#/index.html");

        // Create example component
        local.componentContent = '// Alpine.js component example
Alpine.data(''wheelsApp'', () => ({
    items: [],
    loading: false,

    async init() {
        await this.fetchData();
    },

    async fetchData() {
        this.loading = true;
        try {
            // Replace with your actual API endpoint
            const response = await fetch(''/api/items'');
            this.items = await response.json();
        } catch (error) {
            console.error(''Error fetching data:'', error);
        } finally {
            this.loading = false;
        }
    }
}));';

        file action='write' file='#arguments.path#/app.js' mode='777' output='#trim(local.componentContent)#';
        print.greenLine("Created Alpine.js component at #arguments.path#/app.js");
    }

    private function setupReact(required string path) {
        // Create basic React setup with CDN
        local.indexContent = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wheels + React</title>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <style>
        body { font-family: sans-serif; padding: 2rem; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <div id="root"></div>
    </div>
    <script type="text/babel" src="app.jsx"></script>
</body>
</html>';

        file action='write' file='#arguments.path#/index.html' mode='777' output='#trim(local.indexContent)#';
        print.greenLine("Created React template at #arguments.path#/index.html");

        // Create React component
        local.componentContent = 'const { useState, useEffect } = React;

function App() {
    const [message, setMessage] = useState(''Welcome to React with Wheels!'');
    const [count, setCount] = useState(0);
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            // Replace with your actual API endpoint
            const response = await fetch(''/api/items'');
            const result = await response.json();
            setData(result);
        } catch (error) {
            console.error(''Error fetching data:'', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div>
            <h1>Wheels + React</h1>
            <p>{message}</p>
            <button onClick={() => setCount(count + 1)}>
                Clicked {count} times
            </button>
            {loading && <p>Loading...</p>}
        </div>
    );
}

ReactDOM.render(<App />, document.getElementById(''root''));';

        file action='write' file='#arguments.path#/app.jsx' mode='777' output='#trim(local.componentContent)#';
        print.greenLine("Created React component at #arguments.path#/app.jsx");

        // Create package.json for proper React setup
        local.packageJson = '{
  "name": "wheels-react-frontend",
  "version": "1.0.0",
  "description": "React frontend for Wheels application",
  "scripts": {
    "dev": "echo ''For production setup, run: npm install && npm run build''",
    "build": "echo ''Configure your build process here''"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.3.0"
  }
}';

        file action='write' file='#arguments.path#/package.json' mode='777' output='#trim(local.packageJson)#';
        print.yellowLine("Note: For production React setup, run: cd #arguments.path# && npm install");
    }

    private function setupVue(required string path) {
        // Create basic Vue setup with CDN
        local.indexContent = '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wheels + Vue.js</title>
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
    <style>
        body { font-family: sans-serif; padding: 2rem; }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container" id="app">
        <h1>Wheels + Vue.js</h1>
        <p>{{ message }}</p>
        <button @click="incrementCount">Clicked {{ count }} times</button>
        <div v-if="loading">Loading...</div>
        <ul v-if="!loading && items.length">
            <li v-for="item in items" :key="item.id">{{ item.name }}</li>
        </ul>
    </div>
    <script src="app.js"></script>
</body>
</html>';

        file action='write' file='#arguments.path#/index.html' mode='777' output='#trim(local.indexContent)#';
        print.greenLine("Created Vue.js template at #arguments.path#/index.html");

        // Create Vue component
        local.componentContent = 'const { createApp } = Vue;

createApp({
    data() {
        return {
            message: ''Welcome to Vue.js with Wheels!'',
            count: 0,
            items: [],
            loading: false
        }
    },

    mounted() {
        this.fetchData();
    },

    methods: {
        incrementCount() {
            this.count++;
        },

        async fetchData() {
            this.loading = true;
            try {
                // Replace with your actual API endpoint
                const response = await fetch(''/api/items'');
                this.items = await response.json();
            } catch (error) {
                console.error(''Error fetching data:'', error);
            } finally {
                this.loading = false;
            }
        }
    }
}).mount(''##app'');';

        file action='write' file='#arguments.path#/app.js' mode='777' output='#trim(local.componentContent)#';
        print.greenLine("Created Vue.js component at #arguments.path#/app.js");

        // Create package.json for proper Vue setup
        local.packageJson = '{
  "name": "wheels-vue-frontend",
  "version": "1.0.0",
  "description": "Vue frontend for Wheels application",
  "scripts": {
    "dev": "echo ''For production setup, run: npm install && npm run build''",
    "build": "echo ''Configure your build process here''"
  },
  "dependencies": {
    "vue": "^3.3.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.2.0",
    "vite": "^4.3.0"
  }
}';

        file action='write' file='#arguments.path#/package.json' mode='777' output='#trim(local.packageJson)#';
        print.yellowLine("Note: For production Vue setup, run: cd #arguments.path# && npm install");
    }
}
