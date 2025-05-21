/**
 * Utility for making API requests with consistent error handling
 * Enhanced version with better logging and retry functionality
 */

// API configuration from environment
const API_BASE = import.meta.env.VITE_API_BASE || '/api';
const MOCK_API = import.meta.env.VITE_MOCK_API === 'true';
const DEBUG_API = true; // Set to true to enable verbose console logging

// API response interface
export interface ApiResponse<T> {
  data?: T;
  error?: string;
  status: number;
  headers?: Record<string, string>;
  requestedUrl?: string;
}

// Retry configuration
interface RetryConfig {
  maxRetries: number;
  initialDelay: number;
  maxDelay: number;
  backoffFactor: number;
}

const defaultRetryConfig: RetryConfig = {
  maxRetries: 3,
  initialDelay: 300,
  maxDelay: 3000,
  backoffFactor: 2
};

/**
 * Make an API request with retry capability
 */
export async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {},
  retryConfig: Partial<RetryConfig> = {}
): Promise<ApiResponse<T>> {
  // Merge default retry config with provided options
  const config: RetryConfig = { ...defaultRetryConfig, ...retryConfig };
  let retries = 0;
  let lastError: Error | null = null;
  let delay = config.initialDelay;

  // Create retry wrapper function
  const executeWithRetry = async (): Promise<ApiResponse<T>> => {
    try {
      // Log API request if debug is enabled
      if (DEBUG_API) {
        console.group(`📤 API Request: ${options.method || 'GET'} ${endpoint}`);
        console.log('Request Options:', { ...options, headers: options.headers });
        console.groupEnd();
      }

      // Check for mock API mode
      if (MOCK_API) {
        if (DEBUG_API) console.log(`🔄 Using mock API for ${endpoint}`);
        
        // If this is a real endpoint we want to hit even in mock mode, 
        // the endpoint should start with /real/
        if (!endpoint.startsWith('/real/')) {
          return mockApiResponse<T>(endpoint, options);
        }
        
        // Strip /real/ prefix for real requests
        endpoint = endpoint.replace(/^\/real\//, '');
      }
      
      // Construct the full URL
      const url = `${API_BASE}${endpoint}`;
      
      // Set default headers if not already provided
      const headers = new Headers(options.headers || {});
      if (!headers.has('Content-Type') && options.body) {
        headers.set('Content-Type', 'application/json');
      }
      
      // Add a request ID for tracing
      const requestId = Math.random().toString(36).substring(2, 12);
      headers.set('X-Request-ID', requestId);
      
      // Make the request
      const response = await fetch(url, {
        ...options,
        headers
      });
      
      // Log the response if debug is enabled
      if (DEBUG_API) {
        console.group(`📥 API Response: ${options.method || 'GET'} ${endpoint} (${response.status})`);
        console.log('Status:', response.status);
        console.log('Headers:', Object.fromEntries([...response.headers.entries()]));
        console.groupEnd();
      }
      
      // Collect response headers
      const responseHeaders: Record<string, string> = {};
      response.headers.forEach((value, key) => {
        responseHeaders[key] = value;
      });
      
      // Parse the response body
      let data: T | undefined;
      let error: string | undefined;
      
      try {
        // Process the response based on content type
        if (response.status !== 204) { // Skip for "No Content" responses
          const contentType = response.headers.get('content-type');
          
          if (contentType && contentType.includes('application/json')) {
            // Parse JSON response
            const text = await response.text();
            try {
              data = text ? JSON.parse(text) : undefined;
            } catch (parseError) {
              if (DEBUG_API) console.error('Error parsing JSON:', text);
              throw new Error(`Invalid JSON response: ${parseError instanceof Error ? parseError.message : 'Unknown error'}`);
            }
          } else {
            // Handle non-JSON responses
            const text = await response.text();
            
            // Log response body in debug mode (truncate if too large)
            if (DEBUG_API) {
              const maxLogLength = 500;
              console.log(`Response body (${text.length} chars): ${text.length > maxLogLength ? 
                text.substring(0, maxLogLength) + '...[truncated]' : text}`);
            }
            
            data = text as unknown as T;
          }
        }
      } catch (e) {
        console.error('Error parsing response:', e);
        error = e instanceof Error ? e.message : 'Invalid response format';
      }
      
      // Handle error responses
      if (!response.ok) {
        // Try to extract error message from response
        if (data && typeof data === 'object' && 'message' in data) {
          error = data.message as string;
        } else if (data && typeof data === 'object' && 'error' in data) {
          error = data.error as string;
        } else {
          error = `Request failed with status ${response.status}`;
        }
        
        // For server errors that might be temporary, allow retry
        if (response.status >= 500 && response.status < 600 && retries < config.maxRetries) {
          throw new Error(`Server error: ${error}`);
        }
      }
      
      return {
        data,
        error,
        status: response.status,
        headers: responseHeaders,
        requestedUrl: url
      };
    } catch (e) {
      // Store the error for potential retry
      lastError = e instanceof Error ? e : new Error('Unknown error');
      
      // Check if we should retry
      if (retries < config.maxRetries) {
        retries++;
        
        if (DEBUG_API) {
          console.warn(`⚠️ API request failed, retrying (${retries}/${config.maxRetries}): ${lastError.message}`);
        }
        
        // Wait before retrying with exponential backoff
        await new Promise(resolve => setTimeout(resolve, delay));
        
        // Increase delay for next retry (with maximum cap)
        delay = Math.min(delay * config.backoffFactor, config.maxDelay);
        
        // Try again
        return executeWithRetry();
      }
      
      // We've exhausted all retries, return the error
      console.error('❌ API request failed after retries:', lastError);
      return {
        error: lastError.message,
        status: 0,
        requestedUrl: `${API_BASE}${endpoint}`
      };
    }
  };
  
  // Start the retry process
  return executeWithRetry();
}

/**
 * Mock API response for development
 */
async function mockApiResponse<T>(
  endpoint: string,
  options: RequestInit
): Promise<ApiResponse<T>> {
  // Simulate network delay (randomized for realism)
  const delay = 300 + Math.random() * 700;
  await new Promise(resolve => setTimeout(resolve, delay));
  
  if (DEBUG_API) console.log(`🔸 [Mock API] ${options.method || 'GET'} ${endpoint} (delay: ${delay.toFixed(0)}ms)`);
  
  // Custom mock responses based on endpoint pattern
  if (endpoint.includes('/docker/containers')) {
    return {
      data: { 
        // Mock container data would go here
      } as unknown as T,
      status: 200
    };
  }
  
  // Default mock response
  return {
    data: {} as T,
    status: 200
  };
}

/**
 * Convenience methods for common HTTP methods
 */
export const api = {
  async get<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, { ...options, method: 'GET' });
  },
  
  async post<T>(endpoint: string, data?: any, options: RequestInit = {}): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      ...options,
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined
    });
  },
  
  async put<T>(endpoint: string, data?: any, options: RequestInit = {}): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined
    });
  },
  
  async delete<T>(endpoint: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    return apiRequest<T>(endpoint, { ...options, method: 'DELETE' });
  },
  
  // Special method for handling CFML engine API requests
  async cfml<T>(engine: string, path: string, options: RequestInit = {}): Promise<ApiResponse<T>> {
    // Validate engine parameter
    const validEngines = ['lucee5', 'lucee6', 'adobe2018', 'adobe2021', 'adobe2023'];
    if (!validEngines.includes(engine)) {
      console.error(`Invalid engine: ${engine}. Must be one of: ${validEngines.join(', ')}`);
      return {
        error: `Invalid engine: ${engine}`,
        status: 400
      };
    }
    
    // Make the request to the engine's API endpoint
    return apiRequest<T>(`/${engine}/${path}`, options, {
      // Use a longer timeout for CFML engine requests
      maxRetries: 1,
      initialDelay: 500
    });
  }
};