import type {
  Container,
  CfmlEngine,
  Database,
  CfmlEngineType,
  DatabaseType
} from '@/types';
import { api } from '@/utils/api';

/**
 * Service for interacting with Docker containers through the Docker API
 */
class DockerService {
  private apiBase: string = '/docker';
  private _usingMockData: boolean = false;
  private _lastContainerCheck: number = 0;
  private _cachedContainers: Container[] | null = null;
  private _cachedEngines: Record<string, Container> = {};
  private _cachedDatabases: Record<string, Container> = {};
  private CACHE_TTL: number = 5000; // 5 seconds cache TTL

  // Getter to check if we're using mock data
  get usingMockData(): boolean {
    return this._usingMockData;
  }

  /**
   * Get all containers from Docker API
   * Includes caching with TTL to avoid making too many requests
   */
  async getContainers(forceRefresh: boolean = false): Promise<Container[]> {
    // Check if we have cached data and it's still fresh
    const now = Date.now();
    if (!forceRefresh && this._cachedContainers && (now - this._lastContainerCheck) < this.CACHE_TTL) {
      console.log('Using cached container data...');
      return this._cachedContainers;
    }

    console.log('Fetching containers from Docker API...');

    try {
      // Get all containers including stopped ones
      console.log('API Request:', `${this.apiBase}/containers/json?all=true`);
      const response = await api.get<any[]>(`${this.apiBase}/containers/json?all=true`);

      // Log the full response for debugging
      console.log('API Response Status:', response.status);

      if (response.error || !response.data) {
        console.error('Error fetching containers:', response.error);
        if (this._cachedContainers) {
          console.log('Using last cached container data due to API error...');
          return this._cachedContainers;
        }
        return this.getMockContainers();
      }

      // Check if we got an HTML response instead of JSON
      if (typeof response.data === 'string' && response.data.includes('<!DOCTYPE html>')) {
        console.error('Received HTML instead of JSON. Docker API proxy issue detected.');

        // Use cache if available or fall back to mock data
        if (this._cachedContainers) {
          console.log('Using last cached container data due to API format error...');
          return this._cachedContainers;
        }
        return this.getMockContainers();
      }

      // Ensure data is an array
      if (!Array.isArray(response.data)) {
        console.error('API response is not an array:', typeof response.data);
        if (this._cachedContainers) {
          return this._cachedContainers;
        }
        return this.getMockContainers();
      }

      // Reset mock data flag since we're using real data
      this._usingMockData = false;

      // Process containers and map to our model
      const containers = this.processContainers(response.data);

      // Update cache and timestamp
      this._cachedContainers = containers;
      this._lastContainerCheck = now;

      // Update engine and database caches
      this.updateEngineAndDatabaseCaches(containers);

      return containers;
    } catch (error) {
      console.error('Error in getContainers:', error);

      // Use cache if available
      if (this._cachedContainers) {
        console.log('Using cached container data due to API error...');
        return this._cachedContainers;
      }

      // Fall back to mock data
      return this.getMockContainers();
    }
  }

  /**
   * Process container data from Docker API and convert to our Container model
   */
  private processContainers(apiContainers: any[]): Container[] {
    return apiContainers.map(container => {
      // Look for Wheels-specific labels
      const labels = container.Labels || {};

      // Try to determine container type from labels or image name
      const containerType = this.determineContainerType(container);

      // Map container state to status string
      const status = this.mapContainerStatus(container.State, container.Status);

      // Extract health status if available
      const health = this.extractHealthStatus(container);

      // Extract container name without leading slash
      const name = container.Names && container.Names.length > 0
        ? container.Names[0].replace(/^\//, '')
        : container.Id.substring(0, 12);

      // Map ports
      const ports = this.extractContainerPorts(container);

      // Calculate uptime if container is running
      const uptime = this.calculateUptime(status, container.Status);

      // Determine if this is a Wheels container
      const isWheelsContainer = name.includes('cfwheels') ||
                                 name.includes('wheels') ||
                                 labels['com.github.cfwheels'] !== undefined;

      // Extract Wheels-specific metadata if available
      const wheelsType = labels['com.github.cfwheels.type'] || null;
      const wheelsName = labels['com.github.cfwheels.name'] || null;
      const wheelsVersion = labels['com.github.wheels.version'] || null;

      // Build the container object
      return {
        id: container.Id,
        name,
        type: containerType,
        image: container.Image,
        status,
        health,
        ports,
        created: new Date(container.Created * 1000).toISOString(),
        uptime,
        labels: container.Labels || {},
        isWheelsContainer,
        wheelsType,
        wheelsName,
        wheelsVersion
      };
    });
  }

  /**
   * Determine container type from image name and labels
   */
  private determineContainerType(container: any): 'engine' | 'database' | 'other' {
    // Check labels first (more reliable)
    const labels = container.Labels || {};

    if (labels['com.github.cfwheels.type'] === 'engine') return 'engine';
    if (labels['com.github.cfwheels.type'] === 'database') return 'database';

    // Fall back to image name pattern matching
    const image = container.Image || '';

    if (image.includes('lucee') || image.includes('adobe') || image.includes('coldfusion')) {
      return 'engine';
    } else if (image.includes('mysql') ||
               image.includes('postgres') ||
               image.includes('sqlserver') ||
               image.includes('mssql') ||
               image.includes('h2') ||
               image.includes('oracle')) {
      return 'database';
    }

    // Check container name as last resort
    const name = container.Names && container.Names.length > 0
      ? container.Names[0].replace(/^\//, '')
      : '';

    if (name.includes('lucee') || name.includes('adobe') || name.includes('coldfusion')) {
      return 'engine';
    } else if (name.includes('mysql') ||
               name.includes('postgres') ||
               name.includes('sqlserver') ||
               name.includes('mssql') ||
               name.includes('h2') ||
               name.includes('oracle')) {
      return 'database';
    }

    return 'other';
  }

  /**
   * Map Docker container state to our status enum
   */
  private mapContainerStatus(state: string, statusDetail: string): 'running' | 'stopped' | 'starting' | 'stopping' | 'error' | 'unknown' {
    if (!state) return 'unknown';

    switch (state.toLowerCase()) {
      case 'running':
        return 'running';
      case 'exited':
      case 'dead':
        return 'stopped';
      case 'created':
      case 'restarting':
        return 'starting';
      case 'removing':
      case 'paused':
        return 'stopping';
      default:
        return 'unknown';
    }
  }

  /**
   * Extract health status from container status
   */
  private extractHealthStatus(container: any): 'healthy' | 'unhealthy' | 'starting' | undefined {
    // First check if there's a specific health status in the API response
    if (container.Health && container.Health.Status) {
      const healthStatus = container.Health.Status.toLowerCase();
      if (healthStatus === 'healthy') return 'healthy';
      if (healthStatus === 'unhealthy') return 'unhealthy';
      if (healthStatus === 'starting') return 'starting';
    }

    // Fall back to parsing the Status string
    if (container.Status) {
      if (container.Status.includes('(healthy)')) return 'healthy';
      if (container.Status.includes('(unhealthy)')) return 'unhealthy';
      if (container.Status.includes('(health: starting)')) return 'starting';
    }

    return undefined;
  }

  /**
   * Extract container ports mappings
   */
  private extractContainerPorts(container: any): Record<string, string> {
    const ports: Record<string, string> = {};

    if (container.Ports && Array.isArray(container.Ports)) {
      container.Ports.forEach((port: any) => {
        if (port.PublicPort && port.PrivatePort) {
          ports[port.PrivatePort.toString()] = port.PublicPort.toString();
        }
      });
    }

    return ports;
  }

  /**
   * Calculate container uptime from status string
   */
  private calculateUptime(status: string, statusDetail?: string): string | undefined {
    if (status !== 'running' || !statusDetail) return undefined;

    const uptimeMatch = statusDetail.match(/Up (.*?)( \(|$)/);
    return uptimeMatch ? uptimeMatch[1] : undefined;
  }

  /**
   * Update the engine and database caches based on container list
   */
  private updateEngineAndDatabaseCaches(containers: Container[]): void {
    // Reset caches
    this._cachedEngines = {};
    this._cachedDatabases = {};

    // Populate caches
    containers.forEach(container => {
      if (container.type === 'engine') {
        // Try to identify engine type from name, image, or labels
        if (container.name.includes('lucee5') || container.image.includes('lucee5')) {
          this._cachedEngines['lucee5'] = container;
        } else if (container.name.includes('lucee6') || container.image.includes('lucee6')) {
          this._cachedEngines['lucee6'] = container;
        } else if (container.name.includes('adobe2018') || container.image.includes('adobe2018')) {
          this._cachedEngines['adobe2018'] = container;
        } else if (container.name.includes('adobe2021') || container.image.includes('adobe2021')) {
          this._cachedEngines['adobe2021'] = container;
        } else if (container.name.includes('adobe2023') || container.image.includes('adobe2023')) {
          this._cachedEngines['adobe2023'] = container;
        }
      } else if (container.type === 'database') {
        // Try to identify database type from name, image, or labels
        if (container.name.includes('mysql') || container.image.includes('mysql')) {
          this._cachedDatabases['mysql'] = container;
        } else if (container.name.includes('postgres') || container.image.includes('postgres')) {
          this._cachedDatabases['postgres'] = container;
        } else if (container.name.includes('sqlserver') || container.image.includes('sqlserver')) {
          this._cachedDatabases['sqlserver'] = container;
        } else if (container.name.includes('h2') || container.image.includes('h2')) {
          this._cachedDatabases['h2'] = container;
        } else if (container.name.includes('oracle') || container.image.includes('oracle')) {
          this._cachedDatabases['oracle'] = container;
        }
      }
    });
  }

  /**
   * Get container for a specific CFML engine
   */
  async getEngineContainer(engine: CfmlEngineType | CfmlEngine): Promise<Container | null> {
    // Extract engine key (either from string or object)
    const engineKey = typeof engine === 'string'
      ? engine.toLowerCase()
      : engine.type.toLowerCase();

    // Check cache first
    if (this._cachedEngines[engineKey]) {
      return this._cachedEngines[engineKey];
    }

    // If not in cache, refresh containers and try again
    await this.getContainers(true);

    return this._cachedEngines[engineKey] || null;
  }

  /**
   * Get container for a specific database
   */
  async getDatabaseContainer(database: DatabaseType | Database): Promise<Container | null> {
    // Extract database key (either from string or object)
    const dbKey = typeof database === 'string'
      ? database.toLowerCase()
      : database.type.toLowerCase();

    // H2 is a special case - it's embedded in Lucee, not a separate container
    if (dbKey === 'h2') {
      // Return a virtual container for H2
      return {
        id: 'h2-embedded',
        name: 'h2-embedded',
        type: 'database',
        image: 'h2:embedded',
        status: 'running',
        ports: {},
        created: new Date().toISOString(),
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'h2' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'h2'
      };
    }

    // Check cache first
    if (this._cachedDatabases[dbKey]) {
      return this._cachedDatabases[dbKey];
    }

    // If not in cache, refresh containers and try again
    await this.getContainers(true);

    return this._cachedDatabases[dbKey] || null;
  }

  /**
   * Start a Docker container
   * @deprecated Now showing commands to user instead of executing
   */
  async startContainer(id: string): Promise<void> {
    throw new Error('Container start is now handled by showing commands to user');
  }

  /**
   * Start a Docker Compose service
   * @deprecated Now showing commands to user instead of executing
   */
  async startService(profile: string | null, service?: string): Promise<void> {
    throw new Error('Service start is now handled by showing commands to user');
  }

  /**
   * Stop a Docker container
   */
  async stopContainer(id: string): Promise<void> {
    console.log(`Stopping container ${id}...`);

    try {
      const response = await api.post(`${this.apiBase}/containers/${id}/stop`);

      if (response.error) {
        console.error(`Error stopping container ${id}:`, response.error);
        throw new Error(response.error);
      }

      // Force refresh of containers after action
      setTimeout(() => this.getContainers(true), 500);
    } catch (error) {
      console.error(`Error in stopContainer for ${id}:`, error);
      throw error;
    }
  }

  /**
   * Restart a Docker container
   */
  async restartContainer(id: string): Promise<void> {
    console.log(`Restarting container ${id}...`);

    try {
      const response = await api.post(`${this.apiBase}/containers/${id}/restart`);

      if (response.error) {
        console.error(`Error restarting container ${id}:`, response.error);
        throw new Error(response.error);
      }

      // Force refresh of containers after action
      setTimeout(() => this.getContainers(true), 500);
    } catch (error) {
      console.error(`Error in restartContainer for ${id}:`, error);
      throw error;
    }
  }

  /**
   * Get logs for a Docker container
   */
  async getContainerLogs(id: string, tail: number = 100): Promise<string[]> {
    console.log(`Getting logs for container ${id}...`);

    try {
      // Note: Docker API returns logs as a stream, so we need to handle differently
      // Here we're using the logs?stderr=1&stdout=1&tail=100 endpoint to get recent logs
      const response = await api.get<string>(
        `${this.apiBase}/containers/${id}/logs?stderr=1&stdout=1&tail=${tail}`
      );

      if (response.error || !response.data) {
        console.error(`Error getting logs for container ${id}:`, response.error);
        return [];
      }

      // Split the response into lines and filter out empty ones
      return response.data
        .split('\n')
        .filter(line => line.trim().length > 0)
        .map(line => {
          // Try to remove Docker log prefix bytes if present
          // Docker log stream format usually has 8 bytes of header before each line
          try {
            if (line.charCodeAt(0) <= 2) {
              return line.substring(8);
            }
          } catch (e) {}
          return line;
        });
    } catch (error) {
      console.error(`Error in getContainerLogs for ${id}:`, error);
      return [];
    }
  }

  /**
   * Check if a specific port is available on the host
   */
  async checkPortAvailable(port: number): Promise<boolean> {
    try {
      // Use Docker API to check if any container is using this port
      const containers = await this.getContainers();

      // Check if any container is using this port
      for (const container of containers) {
        for (const [containerPort, hostPort] of Object.entries(container.ports)) {
          if (hostPort === port.toString()) {
            // Port is in use by a container
            return false;
          }
        }
      }

      // Port seems available
      return true;
    } catch (error) {
      console.error(`Error checking port ${port}:`, error);
      return false;
    }
  }

  /**
   * Get Docker Compose profiles in the project
   */
  async getContainerProfiles(): Promise<string[]> {
    console.log('Getting container profiles from compose.yml...');

    // This is specific to our docker-compose setup
    // We can extract profiles from the Docker API using the "com.docker.compose.project" label
    try {
      const containers = await this.getContainers();
      const profiles = new Set<string>();

      // Look for actual profiles in container labels
      containers.forEach(container => {
        const labels = container.labels || {};

        // Extract profile information from labels
        for (const [key, value] of Object.entries(labels)) {
          if (key === 'com.docker.compose.profiles' && value) {
            value.split(',').forEach((profile: string) => {
              profiles.add(profile.trim());
            });
          }
        }
      });

      // If we didn't find any profiles from labels, return default hardcoded ones
      if (profiles.size === 0) {
        return [
          'ui',
          'all',
          'lucee',
          'adobe',
          'db',
          'quick-test',
          'compatibility'
        ];
      }

      return Array.from(profiles);
    } catch (error) {
      console.error('Error in getContainerProfiles:', error);
      return [];
    }
  }

  /**
   * Start a Docker Compose profile
   * Note: This would typically require direct access to the docker-compose CLI
   */
  async startProfile(profile: string): Promise<void> {
    console.log(`Starting profile ${profile}...`);

    // This would typically be implemented using docker-compose commands
    // For this implementation, we'll need to start containers that match the profile
    try {
      // This is a simplified implementation - in a real setup, we would
      // need to call docker-compose up -d --profile <profile> which requires
      // access to the docker-compose CLI
      console.warn('Profile start functionality requires direct access to docker-compose CLI');
      console.warn('This is not implemented directly through the Docker API');

      // For now, we'll just log that this would need to be implemented differently
      return;
    } catch (error) {
      console.error(`Error in startProfile for ${profile}:`, error);
      throw error;
    }
  }

  /**
   * Get Docker info
   */
  async getDockerInfo(): Promise<any> {
    try {
      const response = await api.get(`${this.apiBase}/info`);

      if (response.error || !response.data) {
        console.error('Error fetching Docker info:', response.error);
        return {};
      }

      return response.data;
    } catch (error) {
      console.error('Error in getDockerInfo:', error);
      return {};
    }
  }

  /**
   * Mock container data for display when Docker API is unavailable
   */
  private getMockContainers(): Container[] {
    console.log('Using mock container data...');
    this._usingMockData = true;

    // Generate fresh timestamps
    const now = new Date().toISOString();

    return [
      // CFML Engines
      {
        id: 'mock-lucee5',
        name: 'cfwheels-lucee5-1',
        type: 'engine',
        image: 'cfwheels-test-lucee5:v1.0.2',
        status: 'running',
        health: 'healthy',
        ports: { '60005': '60005' },
        created: now,
        uptime: '2 hours',
        labels: { 'com.github.cfwheels.type': 'engine', 'com.github.cfwheels.name': 'lucee5' },
        isCFWheelsContainer: true,
        cfwheelsType: 'engine',
        cfwheelsName: 'lucee5',
        cfwheelsVersion: 'v1.0.2'
      },
      {
        id: 'mock-lucee6',
        name: 'cfwheels-lucee6-1',
        type: 'engine',
        image: 'cfwheels-test-lucee6:v1.0.2',
        status: 'running',
        health: 'healthy',
        ports: { '60006': '60006' },
        created: now,
        uptime: '2 hours',
        labels: { 'com.github.cfwheels.type': 'engine', 'com.github.cfwheels.name': 'lucee6' },
        isCFWheelsContainer: true,
        cfwheelsType: 'engine',
        cfwheelsName: 'lucee6',
        cfwheelsVersion: 'v1.0.2'
      },
      {
        id: 'mock-adobe2018',
        name: 'cfwheels-adobe2018-1',
        type: 'engine',
        image: 'cfwheels-test-adobe2018:v1.0.2',
        status: 'stopped',
        ports: { '62018': '62018' },
        created: now,
        labels: { 'com.github.cfwheels.type': 'engine', 'com.github.cfwheels.name': 'adobe2018' },
        isCFWheelsContainer: true,
        cfwheelsType: 'engine',
        cfwheelsName: 'adobe2018',
        cfwheelsVersion: 'v1.0.2'
      },
      {
        id: 'mock-adobe2021',
        name: 'cfwheels-adobe2021-1',
        type: 'engine',
        image: 'cfwheels-test-adobe2021:v1.0.2',
        status: 'stopped',
        ports: { '62021': '62021' },
        created: now,
        labels: { 'com.github.cfwheels.type': 'engine', 'com.github.cfwheels.name': 'adobe2021' },
        isCFWheelsContainer: true,
        cfwheelsType: 'engine',
        cfwheelsName: 'adobe2021',
        cfwheelsVersion: 'v1.0.2'
      },
      {
        id: 'mock-adobe2023',
        name: 'cfwheels-adobe2023-1',
        type: 'engine',
        image: 'cfwheels-test-adobe2023:v1.0.1',
        status: 'running',
        health: 'healthy',
        ports: { '62023': '62023' },
        created: now,
        uptime: '2 hours',
        labels: { 'com.github.cfwheels.type': 'engine', 'com.github.cfwheels.name': 'adobe2023' },
        isCFWheelsContainer: true,
        cfwheelsType: 'engine',
        cfwheelsName: 'adobe2023',
        cfwheelsVersion: 'v1.0.1'
      },

      // Databases
      {
        id: 'mock-mysql',
        name: 'cfwheels-mysql-1',
        type: 'database',
        image: 'mysql:8.0',
        status: 'running',
        health: 'healthy',
        ports: { '3306': '3307' },
        created: now,
        uptime: '2 hours',
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'mysql' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'mysql',
        cfwheelsVersion: '8.0'
      },
      {
        id: 'mock-postgres',
        name: 'cfwheels-postgres-1',
        type: 'database',
        image: 'postgres:14',
        status: 'running',
        health: 'healthy',
        ports: { '5432': '5433' },
        created: now,
        uptime: '2 hours',
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'postgres' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'postgres',
        cfwheelsVersion: '14'
      },
      {
        id: 'mock-sqlserver',
        name: 'cfwheels-sqlserver-1',
        type: 'database',
        image: 'cfwheels-sqlserver:v1.0.2',
        status: 'stopped',
        ports: { '1433': '1434' },
        created: now,
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'sqlserver' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'sqlserver',
        cfwheelsVersion: 'v1.0.2'
      },
      // H2 database is represented as a virtual container since it's embedded in Lucee
      {
        id: 'mock-h2',
        name: 'h2-embedded',
        type: 'database',
        image: 'h2:embedded',
        status: 'running',
        ports: {},
        created: now,
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'h2' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'h2'
      },
      {
        id: 'mock-oracle',
        name: 'cfwheels-oracle-1',
        type: 'database',
        image: 'oracle/database:19.3.0',
        status: 'stopped',
        ports: { '1521': '1522' },
        created: now,
        labels: { 'com.github.cfwheels.type': 'database', 'com.github.cfwheels.name': 'oracle' },
        isCFWheelsContainer: true,
        cfwheelsType: 'database',
        cfwheelsName: 'oracle',
        cfwheelsVersion: '19.3.0'
      }
    ];
  }
}

export const dockerService = new DockerService();
